# Pulling fueling-duration run `ca30b35113ef429685724f7f62dbe73e` into `flt-test-fueling-duration`

You've got everything you need on the machine already. Below is the exact sequence — run it as-is from any working directory.

## 1. Prerequisites (one-time per shell session)

### 1a. Load MLflow + Minio credentials

The `pull` command needs `MLFLOW_TRACKING_PASSWORD` plus the AWS/Minio keys (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `MLFLOW_S3_ENDPOINT_URL`) because the artifacts live in Minio for k8s-trained runs.

You've got `mlflow_envs.sh` at `/home/samuel/projects/flt/mlflow_envs.sh`. The skill's helper script will auto-load it (it's the shared-fallback location it searches), so you don't strictly have to source it yourself — but sourcing it makes debugging easier if something goes wrong:

```bash
source /home/samuel/projects/flt/mlflow_envs.sh
```

Confirm the file exports (at minimum):

```sh
export MLFLOW_TRACKING_PASSWORD=...
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export MLFLOW_S3_ENDPOINT_URL=https://minio.flt.prod.k8s.lsyesp.lhgroup.de
```

Note the `prod` in the endpoint URL — since the run was trained on prod, the artifacts are in the prod Minio.

If you keep a per-env file, the script will prefer `/home/samuel/projects/flt/mlflow_envs_prod.sh` over the shared one. Either works.

### 1b. Confirm paths (defaults already match your layout)

The skill reads these env vars but the defaults already resolve to your actual directories, so nothing to set:

- `FLT_ROOT` default `~/projects/flt` matches `/home/samuel/projects/flt`
- `HORIZON_DIR` default `$FLT_ROOT/horizon` matches `/home/samuel/projects/flt/horizon`
- `FLT_TEST_FUELING_DURATION_DIR` default `$FLT_ROOT/flt-test-fueling-duration` matches `/home/samuel/projects/flt/flt-test-fueling-duration`

### 1c. Set up the `hmo` alias (recommended)

```bash
alias hmo="$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py"
```

Add it to `~/.zshrc` if you want it permanent. The helper script uses a PEP 723 inline-deps shebang (`#!/usr/bin/env -S uv run --script`), so `uv` — which you already have — handles mlflow and its deps automatically. No venv activation required. First invocation may take ~30s while uv populates its cache.

## 2. (Optional) Sanity-check the run exists on prod

Before pulling, confirm the run_id is visible on the prod tracking server and that it's a fueling-duration run:

```bash
hmo list fueling-duration-predictor --env prod --n 20
```

You should see `ca30b35113ef429685724f7f62dbe73e` in the output. Note its `run_name` and params — you'll want them for picking a sensible `--tag`.

## 3. Pick a `--tag`

Existing folders in `/home/samuel/projects/flt/flt-test-fueling-duration/models/` follow this convention:

- `duration_notime_xgb_*`
- `duration_notime_light_*`
- `duration_notime_hist_*`
- `duration_liftoff_light_*`

Pick a tag that captures the algorithm (xgb / light / hist) and feature-set hint (notime, liftoff, etc.) based on the run's params or run_name. If you don't pass `--tag`, the default is plain `duration`, which will land as `duration_22042026_ca30b35113ef429685724f7f62dbe73e` — fine but less informative.

Peek at existing folders first to stay consistent:

```bash
ls /home/samuel/projects/flt/flt-test-fueling-duration/models/
```

## 4. Run the pull

Minimal (default tag `duration`):

```bash
hmo pull ca30b35113ef429685724f7f62dbe73e --env prod
```

Recommended (explicit informative tag — substitute the algorithm/feature hint that matches the run):

```bash
hmo pull ca30b35113ef429685724f7f62dbe73e --env prod --tag duration_notime_xgb
```

Note: `--kind` is **not** used for fueling-duration — it's only required for `uplift-order-predictor`. The destination subfolder is automatic (the fueling test repo's `models/` root).

The model will land at:

```
/home/samuel/projects/flt/flt-test-fueling-duration/models/<tag>_22042026_ca30b35113ef429685724f7f62dbe73e/
```

(Date `22042026` is today, 2026-04-22, in `ddmmyyyy`.)

## 5. If the destination already exists

The pull is non-destructive by default and will error if the target directory already exists. To replace it:

```bash
hmo pull ca30b35113ef429685724f7f62dbe73e --env prod --tag duration_notime_xgb --force
```

## 6. Run `test.py`

Once the folder is in place, `test.py` in the fueling test repo will iterate over `models/` and pick it up automatically — that part is outside this skill's scope. Run it however you normally do inside `flt-test-fueling-duration`.

## Troubleshooting

- **`MLFLOW_TRACKING_PASSWORD unset` error** — the script couldn't find a creds file. Double-check `/home/samuel/projects/flt/mlflow_envs.sh` exists and exports the var, or `source` it manually in your shell.
- **Run not found** — you may have trained on int rather than prod. Re-run the list command against the other env (`--env int`) to confirm. Never pull a run_id against the wrong `--env`.
- **uv not found** — shouldn't happen on your machine, but fallback is `cd /home/samuel/projects/flt/horizon && source venv/bin/activate && python "$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py" pull ca30b35113ef429685724f7f62dbe73e --env prod --tag duration_notime_xgb`.
- **Minio download fails with 403/SignatureDoesNotMatch** — almost always means the AWS keys in `mlflow_envs.sh` are for int when you're hitting prod (or vice-versa). Check `MLFLOW_S3_ENDPOINT_URL` host matches the `--env`.
