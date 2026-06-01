#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "mlflow>=3.0,<4.0",
#     "boto3",
# ]
# ///
"""horizon_models — train, list, and pull ML models for the horizon MLflow projects.

Usage:
  horizon_models.py train <subproject> [--k8s] [--env int|prod] [-- <mlflow-args>...]
  horizon_models.py list <subproject> [--n 10] [--env int|prod]
  horizon_models.py pull <run_id> [--tag NAME] [--env int|prod] [--force]

The PEP 723 header above lets `uv` run this directly — no venv activation needed.
First run on a fresh machine downloads mlflow (~30s); subsequent runs are cached.
If you don't have uv, `python horizon_models.py ...` works too as long as mlflow
is importable (e.g. the horizon venv is active).

Path configuration via env vars (all have sensible defaults):
  FLT_ROOT                       default: ~/projects/flt
  HORIZON_DIR                    default: $FLT_ROOT/horizon
  FLT_TEST_FUELING_DURATION_DIR  default: $FLT_ROOT/flt-test-fueling-duration
  FLT_TEST_UPLIFT_PREDICTION_DIR default: $FLT_ROOT/flt-test-uplift-prediction

Credentials are auto-loaded from (first match wins):
  $FLT_MLFLOW_ENV_FILE             explicit override
  $FLT_ROOT/mlflow_envs_{env}.sh   per-env (int / prod)
  $FLT_ROOT/mlflow_envs.sh         shared fallback

The file is plain `export KEY=VALUE` lines. Put these in it:
  MLFLOW_TRACKING_PASSWORD   required for all commands
  AWS_ACCESS_KEY_ID          required for `pull`
  AWS_SECRET_ACCESS_KEY      required for `pull`
  MLFLOW_S3_ENDPOINT_URL     required for `pull`

Tracking URI and username are hardcoded in this script per --env.
"""
import argparse
import os
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path


def _env_path(var: str, default: Path) -> Path:
    return Path(os.environ.get(var, str(default))).expanduser()


FLT_ROOT = Path(os.environ.get("FLT_ROOT", "~/projects/flt")).expanduser()
HORIZON_DIR = _env_path("HORIZON_DIR", FLT_ROOT / "horizon")
TEST_FUELING = _env_path("FLT_TEST_FUELING_DURATION_DIR", FLT_ROOT / "flt-test-fueling-duration")
TEST_UPLIFT = _env_path("FLT_TEST_UPLIFT_PREDICTION_DIR", FLT_ROOT / "flt-test-uplift-prediction")

ENVS = {
    "int": {
        "MLFLOW_TRACKING_URI": "https://int.lsyesp.lhgroup.de/flt/mlflow/",
        "MLFLOW_TRACKING_USERNAME": "admin",
        "backend_config": "espint.json",
    },
    "prod": {
        "MLFLOW_TRACKING_URI": "https://prod.lsyesp.lhgroup.de/flt/mlflow/",
        "MLFLOW_TRACKING_USERNAME": "admin",
        "backend_config": "espprod.json",
    },
}

# Maps horizon subproject (also the MLflow experiment name) to:
#   test_repo: absolute path to the sibling test repo (from env)
#   artifacts: MLflow artifact subpath → (test-repo models/ subfolder, default tag)
# The "model" fallback under uplift-order-predictor covers future runs if its
# log_model call is standardized to use "model" as the artifact subpath.
SUBPROJECTS = {
    "fueling-duration-predictor": {
        "test_repo": TEST_FUELING,
        "mode": "artifact",  # destination picked by logged-model name
        "artifacts": {
            "model": {"subdir": "", "default_tag": "duration"},
        },
    },
    "uplift-order-predictor": {
        "test_repo": TEST_UPLIFT,
        "mode": "kind",  # training logs models under algo names (HistGradientBoosting, ...),
                         # not semantic purpose, so the user specifies --kind.
        "kinds": {
            "uplift": {"subdir": "uplift", "default_tag": "uplift"},
            "uplift_correction": {"subdir": "uplift_correction", "default_tag": "uplift_correction"},
        },
    },
    "schedule-predictor-departures": {
        "test_repo": TEST_UPLIFT,
        "mode": "artifact",
        "artifacts": {
            "model": {"subdir": "deps", "default_tag": "deps"},
        },
    },
    "schedule-predictor-minutes": {
        "test_repo": TEST_UPLIFT,
        "mode": "artifact",
        "artifacts": {
            "model": {"subdir": "mins", "default_tag": "mins"},
        },
    },
}


def _load_creds_file(env: str) -> Path | None:
    """Load AWS_*/MLFLOW_S3_ENDPOINT_URL from a shell env file if one exists.

    Uses `setdefault` so values already in the shell env win. Returns the path
    that was loaded, or None.
    """
    candidates: list[Path] = []
    explicit = os.environ.get("FLT_MLFLOW_ENV_FILE")
    if explicit:
        candidates.append(Path(explicit).expanduser())
    candidates.append(FLT_ROOT / f"mlflow_envs_{env}.sh")
    candidates.append(FLT_ROOT / "mlflow_envs.sh")

    for path in candidates:
        if not path.is_file():
            continue
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[len("export "):]
            key, eq, val = line.partition("=")
            if not eq:
                continue
            os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))
        return path
    return None


def set_env(env: str) -> dict:
    cfg = ENVS[env]
    os.environ["MLFLOW_TRACKING_URI"] = cfg["MLFLOW_TRACKING_URI"]
    os.environ["MLFLOW_TRACKING_USERNAME"] = cfg["MLFLOW_TRACKING_USERNAME"]
    _load_creds_file(env)
    if not os.environ.get("MLFLOW_TRACKING_PASSWORD"):
        sys.exit(
            "MLFLOW_TRACKING_PASSWORD is not set.\n"
            "Export it in your shell, or add it to an env file searched by this script "
            f"($FLT_MLFLOW_ENV_FILE, {FLT_ROOT}/mlflow_envs_{env}.sh, {FLT_ROOT}/mlflow_envs.sh)."
        )
    return cfg


def cmd_train(args, extras):
    cfg = set_env(args.env)
    if not HORIZON_DIR.is_dir():
        sys.exit(f"HORIZON_DIR not found: {HORIZON_DIR} (set HORIZON_DIR or FLT_ROOT)")
    subproject_dir = HORIZON_DIR / args.subproject
    if not subproject_dir.is_dir():
        sys.exit(f"Unknown subproject directory: {subproject_dir}")

    cmd = ["mlflow", "run", args.subproject, "--experiment-name", args.subproject]
    if args.k8s:
        cmd += ["--build-image", "--backend", "kubernetes",
                "--backend-config", cfg["backend_config"]]
    cmd += extras

    print(f"[horizon_models] env={args.env}  backend={'kubernetes' if args.k8s else 'local'}")
    print(f"[horizon_models] cwd={HORIZON_DIR}")
    print(f"[horizon_models] $ {' '.join(cmd)}")
    os.chdir(HORIZON_DIR)
    os.execvp(cmd[0], cmd)


def cmd_list(args):
    set_env(args.env)
    from mlflow.tracking import MlflowClient

    client = MlflowClient()
    exp = client.get_experiment_by_name(args.subproject)
    if exp is None:
        sys.exit(f"No MLflow experiment named '{args.subproject}' on {args.env}")

    runs = client.search_runs(
        [exp.experiment_id],
        order_by=["attributes.start_time DESC"],
        max_results=args.n,
    )
    if not runs:
        print(f"No runs found for experiment '{args.subproject}' on {args.env}")
        return

    print(f"{'RUN_ID':<34} {'WHEN':<17} {'STATUS':<9} RUN_NAME")
    for r in runs:
        start = datetime.fromtimestamp(r.info.start_time / 1000).strftime("%Y-%m-%d %H:%M")
        run_name = r.data.tags.get("mlflow.runName", "")
        print(f"{r.info.run_id:<34} {start:<17} {r.info.status:<9} {run_name}")


def _logged_models_for_run(client, run):
    """Return the MLflow 3.x LoggedModel entities attached to a run, if any."""
    outputs = getattr(run, "outputs", None)
    model_outputs = getattr(outputs, "model_outputs", None) if outputs else None
    logged = []
    if model_outputs:
        for mo in model_outputs:
            mid = getattr(mo, "model_id", None)
            if not mid:
                continue
            try:
                logged.append(client.get_logged_model(mid))
            except Exception:
                pass
    if not logged:
        try:
            logged = client.search_logged_models(
                experiment_ids=[run.info.experiment_id],
                filter_string=f"source_run_id = '{run.info.run_id}'",
            )
        except Exception:
            pass
    return logged


def _resolve_artifact_mode(client, run, sp):
    """(artifact_name, uri) when the subproject maps artifact names → subdirs."""
    logged = _logged_models_for_run(client, run)
    if logged:
        matches = {lm.name: lm for lm in logged if lm.name in sp["artifacts"]}
        if not matches:
            available = [lm.name for lm in logged]
            sys.exit(
                f"Run {run.info.run_id} has logged models but none match the expected names.\n"
                f"Found: {available}\n"
                f"Expected one of: {list(sp['artifacts'])}"
            )
        if len(matches) > 1:
            sys.exit(f"Multiple matching logged models: {list(matches)} — ambiguous.")
        name, lm = next(iter(matches.items()))
        return name, lm.artifact_location

    # MLflow 2.x fallback
    root_paths = {a.path for a in client.list_artifacts(run.info.run_id)}
    matches = [n for n in sp["artifacts"] if n in root_paths]
    if not matches:
        sys.exit(
            f"Run {run.info.run_id} has no recognized model artifact.\n"
            f"Logged-models API returned none; run-level artifacts are "
            f"{sorted(root_paths) or '(none)'}.\n"
            f"Expected one of: {list(sp['artifacts'])}"
        )
    if len(matches) > 1:
        sys.exit(f"Run has multiple run-level model artifacts: {matches} — ambiguous.")
    return matches[0], f"runs:/{run.info.run_id}/{matches[0]}"


def _resolve_kind_mode(client, run, sp, kind):
    """(logged_model_name, uri) when the subproject needs an explicit --kind."""
    if not kind:
        sys.exit(
            f"--kind is required for this subproject. Valid values: {list(sp['kinds'])}"
        )
    if kind not in sp["kinds"]:
        sys.exit(f"Unknown --kind '{kind}'. Valid: {list(sp['kinds'])}")
    logged = _logged_models_for_run(client, run)
    if not logged:
        sys.exit(
            f"Run {run.info.run_id} has no logged models.\n"
            f"Cannot pull a --kind={kind} model from a run without one."
        )
    if len(logged) > 1:
        names = [lm.name for lm in logged]
        sys.exit(
            f"Run {run.info.run_id} has multiple logged models ({names}) — ambiguous.\n"
            f"This skill expects one model per run for uplift-order-predictor."
        )
    lm = logged[0]
    return lm.name, lm.artifact_location


def cmd_pull(args):
    set_env(args.env)
    import mlflow
    from mlflow.tracking import MlflowClient

    client = MlflowClient()
    try:
        run = client.get_run(args.run_id)
    except Exception as e:
        sys.exit(f"Could not fetch run {args.run_id} from {args.env}: {e}")

    exp = client.get_experiment(run.info.experiment_id)
    subproject = exp.name
    if subproject not in SUBPROJECTS:
        sys.exit(
            f"Experiment '{subproject}' is not a known subproject.\n"
            f"Known: {list(SUBPROJECTS)}"
        )
    sp = SUBPROJECTS[subproject]

    if sp["mode"] == "kind":
        artifact_name, source_uri = _resolve_kind_mode(client, run, sp, args.kind)
        art_cfg = sp["kinds"][args.kind]
    else:
        artifact_name, source_uri = _resolve_artifact_mode(client, run, sp)
        art_cfg = sp["artifacts"][artifact_name]

    tag = args.tag or art_cfg["default_tag"]
    ddmmyyyy = datetime.fromtimestamp(run.info.start_time / 1000).strftime("%d%m%Y")
    final_name = f"{tag}_{ddmmyyyy}_{args.run_id}"

    test_repo = sp["test_repo"]
    if not test_repo.is_dir():
        sys.exit(
            f"Test repo not found: {test_repo}\n"
            f"Set FLT_ROOT or the per-repo env var to point at it."
        )
    dest_parent = test_repo / "models" / art_cfg["subdir"] if art_cfg["subdir"] else test_repo / "models"
    dest_dir = dest_parent / final_name

    if dest_dir.exists():
        if not args.force:
            sys.exit(f"Destination already exists: {dest_dir} (use --force to overwrite)")
        shutil.rmtree(dest_dir)

    dest_parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        local_path = Path(mlflow.artifacts.download_artifacts(artifact_uri=source_uri, dst_path=tmp))
        # MLflow 3.x logged-model dirs wrap the actual model in `artifacts/`.
        # If the top level doesn't already have an MLmodel file, unwrap once.
        if not (local_path / "MLmodel").is_file() and (local_path / "artifacts" / "MLmodel").is_file():
            local_path = local_path / "artifacts"
        shutil.move(str(local_path), dest_dir)

    print(f"[horizon_models] pulled '{artifact_name}' from run {args.run_id}")
    print(f"[horizon_models]   subproject: {subproject}")
    print(f"[horizon_models]   source:     {source_uri}")
    print(f"[horizon_models]   → {dest_dir}")


def main():
    parser = argparse.ArgumentParser(prog="horizon_models")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_train = sub.add_parser("train", help="run mlflow training for a subproject")
    p_train.add_argument("subproject", choices=sorted(SUBPROJECTS))
    p_train.add_argument("--k8s", action="store_true",
                         help="run on Kubernetes (default: local)")
    p_train.add_argument("--env", choices=["int", "prod"], default="int")

    p_list = sub.add_parser("list", help="show recent MLflow runs for a subproject")
    p_list.add_argument("subproject", choices=sorted(SUBPROJECTS))
    p_list.add_argument("--n", type=int, default=10)
    p_list.add_argument("--env", choices=["int", "prod"], default="int")

    p_pull = sub.add_parser("pull", help="pull a model from MLflow into its test repo")
    p_pull.add_argument("run_id")
    p_pull.add_argument("--tag", help="name prefix (default: subproject-specific)")
    p_pull.add_argument("--kind", choices=["uplift", "uplift_correction"],
                        help="required for uplift-order-predictor; picks test-repo subfolder")
    p_pull.add_argument("--env", choices=["int", "prod"], default="int")
    p_pull.add_argument("--force", action="store_true",
                        help="overwrite existing destination dir")

    args, extras = parser.parse_known_args()
    if args.cmd != "train" and extras:
        parser.error(f"unrecognized arguments: {' '.join(extras)}")

    if args.cmd == "train":
        cmd_train(args, extras)
    elif args.cmd == "list":
        cmd_list(args)
    elif args.cmd == "pull":
        cmd_pull(args)


if __name__ == "__main__":
    main()
