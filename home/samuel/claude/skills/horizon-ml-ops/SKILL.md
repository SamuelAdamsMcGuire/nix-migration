---
name: horizon-ml-ops
description: >-
  Operates the horizon ML monorepo workflow — kicks off MLflow training runs (local or on
  the ESP Kubernetes cluster against the int/prod MLflow tracking servers), lists recent
  runs, and pulls trained models out of MLflow/Minio into the sibling flt-test-*
  evaluation repos. Covers the subprojects fueling-duration-predictor, uplift-order-predictor
  (both uplift and uplift_correction variants), schedule-predictor-departures, and
  schedule-predictor-minutes.
  Use this skill whenever the user works in horizon/, mentions training or retraining an
  ML model, asks to kick off an mlflow run, wants to list or inspect recent MLflow runs,
  or asks to pull / fetch / copy / download / get a trained model into one of the
  flt-test-fueling-duration or flt-test-uplift-prediction repos. Also triggers on mentions
  of "mlflow run", "MLflow tracking server", "espint.json", "espprod.json", run_id
  references, artifact subpaths like "uplift" / "uplift_correction" / "model", the
  "duration_*_ddmmyyyy_<runid>" naming convention, "evaluate this run locally", "test this
  model", or ambiguous phrases like "retrain the fueling model" / "get the latest uplift
  model" where the user clearly means the horizon → test-repo workflow without naming it.
  This skill is scoped to running mlflow and moving trained model artifacts. It does NOT
  modify training code, manage training data in Minio (use mc / boto3 directly), run
  evaluations in the test repos (that's test.py there), touch the MLflow Model Registry,
  or deploy / serve models. For changes to the training code itself (features,
  hyperparameters, parsers), this is regular Python work on the horizon subproject — not
  a skill operation.
---

# horizon-ml-ops

Thin operational wrapper around the horizon MLflow monorepo. Three operations:

1. **train** — run an MLflow project locally or on Kubernetes with the right tracking-server env vars and backend-config.
2. **list** — show the most recent runs on the MLflow tracking server for a given subproject.
3. **pull** — download a run's trained model from MLflow (artifacts live in Minio for k8s runs) into the sibling `flt-test-*` repo so `test.py` there can evaluate it.

## When to use

- User asks to **train / retrain / kick off a training run** for a horizon subproject.
- User asks to **list recent runs**, find a run_id, or see what's on the tracking server.
- User asks to **pull / fetch / copy / download / get a model** into the test repo for local evaluation.
- User references an **MLflow run_id** and wants to do something with it.
- User says "I want to try the latest fueling model locally" or "get the best uplift model from prod" — the intent maps to pull.

## When NOT to use

- **Editing training code** — adding features, changing model variants, modifying parsers, writing new queries. That's regular engineering on the horizon subproject; read the subproject's `main.py` and edit normally.
- **Managing training data** in Minio — `mc cp` / `mc ls` / the boto3 blocks inside each subproject's `main.py`. Do that directly.
- **Running evaluations** — the `flt-test-*/test.py` scripts evaluate models already placed in `models/`. This skill only *delivers* models; it doesn't score them.
- **Model Registry / staging promotion** — nothing in horizon currently uses the MLflow Model Registry. Out of scope.
- **Deployment / serving** — there's a separate deployment repo for that (see the horizon README's fueling-duration-predictor section).

## Helper script

All three commands shell out to `scripts/horizon_models.py` inside this skill directory. The script uses a PEP 723 inline-dependency header, so `uv` handles the env automatically — no venv activation needed:

```bash
alias hmo="$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py"
hmo list fueling-duration-predictor --env prod
```

The shebang is `#!/usr/bin/env -S uv run --script`, which makes the script self-contained: the first invocation on a fresh machine downloads `mlflow` into uv's cache (~30s), subsequent invocations are instant. Requires uv (already installed on the ESP dev machines and Theia; `curl -LsSf https://astral.sh/uv/install.sh | sh` otherwise).

**Fallback if uv isn't available:** activate the horizon venv and invoke the script via `python`:

```bash
cd "$HORIZON_DIR"
source venv/bin/activate
python "$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py" list fueling-duration-predictor --env prod
```

### Path configuration (env vars)

The script reads these from the environment; defaults assume a standard layout under `~/projects/flt/`. Set only the ones that deviate.

| Env var | Default | Purpose |
|---|---|---|
| `FLT_ROOT` | `~/projects/flt` | Parent dir of horizon + sibling test repos |
| `HORIZON_DIR` | `$FLT_ROOT/horizon` | Where the MLflow subprojects live |
| `FLT_TEST_FUELING_DURATION_DIR` | `$FLT_ROOT/flt-test-fueling-duration` | Destination for fueling-duration pulls |
| `FLT_TEST_UPLIFT_PREDICTION_DIR` | `$FLT_ROOT/flt-test-uplift-prediction` | Destination for uplift / deps / mins pulls |
| `FLT_MLFLOW_ENV_FILE` | *(unset)* | Explicit path to a shell env file with credentials (see below). |

### Credentials file

All commands need `MLFLOW_TRACKING_PASSWORD`; `pull` additionally needs AWS/Minio keys. The script holds no credentials — it auto-loads them from the first file it finds:

1. `$FLT_MLFLOW_ENV_FILE` (explicit override)
2. `$FLT_ROOT/mlflow_envs_{env}.sh` (per-env, where `{env}` is `int` or `prod`)
3. `$FLT_ROOT/mlflow_envs.sh` (shared fallback)

The file is a plain shell snippet. Minimum contents:

```sh
export MLFLOW_TRACKING_PASSWORD=...          # required for all commands
export AWS_ACCESS_KEY_ID=...                 # required for pull
export AWS_SECRET_ACCESS_KEY=...             # required for pull
export MLFLOW_S3_ENDPOINT_URL=https://minio.flt.{int,prod}.k8s.lsyesp.lhgroup.de   # required for pull
```

Keep it outside any committed repo. If the vars are already exported in the shell, the script leaves them alone (`setdefault`). If `MLFLOW_TRACKING_PASSWORD` is still unset after loading, the script exits with a clear error pointing to the search paths.

## Commands

### train

```bash
hmo train <subproject> [--k8s] [--env int|prod] [-- <mlflow-args>...]
```

- Defaults: `--env int`, local backend.
- Sets `MLFLOW_TRACKING_URI / USERNAME / PASSWORD` for the chosen env, then `exec`s `mlflow run <subproject> --experiment-name <subproject>` from the horizon root.
- `--k8s` adds `--build-image --backend kubernetes --backend-config esp<env>.json`.
- Extra args after `--` are forwarded to `mlflow run` (e.g., `-Pengine=oracle+oracledb://...` for subprojects that need a DB engine param).

Examples:
```bash
hmo train fueling-duration-predictor
scripts/horizon_models.py train uplift-order-predictor --k8s --env prod
scripts/horizon_models.py train schedule-predictor-minutes --k8s -- -Pengine=oracle+oracledb://...
```

### list

```bash
hmo list <subproject> [--n 10] [--env int|prod]
```

Prints recent runs (run_id, timestamp, status, run_name) so the user can pick one to pull. Default `--n 10`. Use this before `pull` whenever the user doesn't already have a run_id in hand.

### pull

```bash
hmo pull <run_id> [--kind uplift|uplift_correction] [--tag NAME] [--env int|prod] [--force]
```

- Looks up the run → experiment name → horizon subproject → sibling test repo + `models/` subfolder.
- For `fueling-duration-predictor`, `schedule-predictor-departures`, `schedule-predictor-minutes`: the logged-model name (`model`) determines destination automatically.
- For `uplift-order-predictor`: training logs models under algorithm names (`HistGradientBoosting`, `DummyRegressor`, etc.) rather than semantic kind, so `--kind` is **required** to pick `uplift` vs `uplift_correction` as the destination subfolder.
- Works with both MLflow 3.x runs (logged-model entities under `<bucket>/<exp_id>/models/m-<uuid>/`) and pre-3.x runs (model under the run's own artifact tree) — tries the 3.x API first, falls back to the run-level lookup.
- Downloads and places at `<test-repo>/models/<subfolder>/<tag>_<ddmmyyyy>_<run_id>/`, matching the naming convention `test.py` already iterates over.
- `--tag` overrides the default prefix (e.g., `--tag duration_notime_xgb` → `duration_notime_xgb_22042026_<run_id>`). Choose a tag that reflects the feature set or variant, mirroring existing folder names in the destination test repo.

## Subproject → test repo mapping

| Horizon subproject | Mode | Test repo | `models/` subfolder | Default tag |
|---|---|---|---|---|
| `fueling-duration-predictor` | by logged-model name (`model`) | `flt-test-fueling-duration` | (root) | `duration` |
| `uplift-order-predictor` | **`--kind uplift`** | `flt-test-uplift-prediction` | `uplift` | `uplift` |
| `uplift-order-predictor` | **`--kind uplift_correction`** | `flt-test-uplift-prediction` | `uplift_correction` | `uplift_correction` |
| `schedule-predictor-departures` | by logged-model name (`model`) | `flt-test-uplift-prediction` | `deps` | `deps` |
| `schedule-predictor-minutes` | by logged-model name (`model`) | `flt-test-uplift-prediction` | `mins` | `mins` |

The `uplift-order-predictor` training loop starts one MLflow run per algorithm and logs the model under the *algorithm* name (`HistGradientBoosting`, `DummyRegressor`, …). Nothing on the run indicates whether it trained the primary uplift model or the correction model, so the user passes that context via `--kind`. If the training code is later changed to tag runs with `kind=...`, or split into two experiments, this flag can be removed.

`taxi-in` has no evaluation repo yet and isn't wired into this skill.

## Choosing a `--tag`

Recent existing folders in the destinations (look before picking a tag so the naming stays consistent):

- `flt-test-fueling-duration/models/`: `duration_notime_xgb_*`, `duration_notime_light_*`, `duration_notime_hist_*`, `duration_liftoff_light_*`.
- `flt-test-uplift-prediction/models/uplift_correction/`: `uplift_correction_hist_*`, `uplift_correction_7airports`, `variant_i_seatbin_only`.

If the user doesn't specify, pick a tag that includes the algorithm (xgb/light/hist) and a short feature-set hint (notime, liftoff, hist) by reading the run's params or run_name.

## Environments

Two tracking servers. Both use the same credentials.

| `--env` | `MLFLOW_TRACKING_URI` | Backend config |
|---|---|---|
| `int` (default) | `https://int.lsyesp.lhgroup.de/flt/mlflow/` | `espint.json` |
| `prod` | `https://prod.lsyesp.lhgroup.de/flt/mlflow/` | `espprod.json` |

`--env` applies identically to `train`, `list`, and `pull`.

## Constraints

- **Operational skill only.** This skill runs mlflow and moves files. It does not modify training code, training data, or the test repos' evaluation scripts.
- **uv is the expected runtime** (via the script's PEP 723 shebang). If uv isn't available, activate the horizon venv and invoke via `python <script.py> ...` instead.
- **K8s training prerequisite:** `docker login esp-cr.artifactory.lsyesp.lhgroup.de` must be done in the current shell session before `--k8s` will build the image.
- **Paths are resolved from env vars** (`FLT_ROOT`, `HORIZON_DIR`, `FLT_TEST_FUELING_DURATION_DIR`, `FLT_TEST_UPLIFT_PREDICTION_DIR`) with defaults under `~/projects/flt/`. Teammates with a different layout set the appropriate var once (e.g., in their shell rc) instead of editing the script.
- **Destination overwrite is opt-in.** `pull` errors if the target directory exists; pass `--force` to replace. Hand-named experimental folders (e.g., `variant_i_seatbin_only`) will never collide with the canonical `<tag>_<ddmmyyyy>_<runid>` pattern.
- **Never run against a run_id from the wrong `--env`.** `pull` will cleanly fail if the run doesn't exist on the chosen server, but double-check if you're unsure.
