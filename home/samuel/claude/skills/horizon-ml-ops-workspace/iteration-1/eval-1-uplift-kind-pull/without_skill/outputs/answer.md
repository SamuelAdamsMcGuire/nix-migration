# Pulling uplift-correction MLflow run `950267949ce44f4db686d0692a4d4d4f` into the eval repo

Below is a guide to fetch the model artifacts for MLflow run `950267949ce44f4db686d0692a4d4d4f` from the prod MLflow tracking server and drop them into `flt-test-uplift-prediction` using the naming convention your repo already follows.

---

## 1. Prerequisites

### MLflow + S3 credentials

The horizon MLflow stack stores artifacts in Minio (S3-compatible), so you need **both** the tracking-server creds and the S3 creds. They are already in `~/projects/flt/mlflow_envs.sh`. Source them into your current shell:

```bash
source ~/projects/flt/mlflow_envs.sh
```

That exports:

- `MLFLOW_TRACKING_URI` (https://prod.lsyesp.lhgroup.de/flt/mlflow/)
- `MLFLOW_TRACKING_USERNAME`, `MLFLOW_TRACKING_PASSWORD`
- `MLFLOW_S3_ENDPOINT_URL` (Minio)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

Verify they are set:

```bash
echo "$MLFLOW_TRACKING_URI"
echo "$MLFLOW_S3_ENDPOINT_URL"
```

### Python tooling

You said `uv` is installed. The eval repo (`flt-test-uplift-prediction`) already has an `mlflow` dependency via `uv sync`, so running `mlflow artifacts download` through `uv run` inside that repo is the cleanest option — it picks up the synced environment without polluting your system Python.

```bash
cd ~/projects/flt/flt-test-uplift-prediction
uv sync        # only needed if you haven't already
```

### Network

`prod.lsyesp.lhgroup.de` and the Minio endpoint must be reachable from your machine (VPN / hosts route). If artifact download hangs, it is almost always the Minio endpoint, not the tracking server.

---

## 2. Confirm the run is what you expect

Before pulling, sanity-check the run id. If it's the wrong experiment or a DummyRegressor run, you don't want to waste a download or clobber an existing folder.

```bash
uv run --with mlflow python - <<'PY'
import os, mlflow
from mlflow.tracking import MlflowClient
client = MlflowClient()
run = client.get_run("950267949ce44f4db686d0692a4d4d4f")
print("experiment_id:", run.info.experiment_id)
print("run_name:     ", run.info.run_name)
print("status:       ", run.info.status)
print("start_time:   ", run.info.start_time)
print("metrics:      ", dict(run.data.metrics))
print("artifact_uri: ", run.info.artifact_uri)
print("artifacts:")
for a in client.list_artifacts(run.info.run_id):
    print(" -", a.path, "(dir)" if a.is_dir else f"({a.file_size} bytes)")
PY
```

You are looking for an artifact sub-directory that holds the model — for this pipeline it's typically one of `uplift_correction`, `uplift`, `HistGradientBoosting`, etc. (horizon's `uplift-order-predictor/utils.py` calls `mlflow.sklearn.log_model(model, model_name, ...)`, so the sub-path equals the training loop's `model_name`). Note the exact sub-path printed — call it `<ARTIFACT_SUBPATH>` below.

The repo convention (see `flt-test-uplift-prediction/models/uplift_correction/`) is:

```
models/<kind>/<kind>_<ddmmyyyy>_<full_run_id>/
```

where `<kind>` is `uplift_correction` (or `uplift`, `deps`, `mins`) and `<ddmmyyyy>` is the run's start date. For run `950267949...` you should end up with:

```
models/uplift_correction/uplift_correction_<ddmmyyyy>_950267949ce44f4db686d0692a4d4d4f/
```

Note: `models/uplift_correction/uplift_correction_hist_19032026_950267949ce44f4db686d0692a4d4d4f/` already exists in the repo — it has the `_hist_` infix. If that one was created for this same run earlier (check its `MLmodel` file — its `run_id:` field will match), you may already have what you need and can skip the download. Otherwise pick a non-colliding folder name.

---

## 3. Download the artifacts

From the eval repo root:

```bash
cd ~/projects/flt/flt-test-uplift-prediction
```

Set convenience variables (fill in `<ARTIFACT_SUBPATH>` and `<DDMMYYYY>` from step 2):

```bash
RUN_ID=950267949ce44f4db686d0692a4d4d4f
ARTIFACT_SUBPATH=uplift_correction           # confirm from step 2
DATE_TAG=<DDMMYYYY>                          # e.g. 19032026, from run.info.start_time
DEST=models/uplift_correction/uplift_correction_${DATE_TAG}_${RUN_ID}
```

Pull the artifact folder. `mlflow artifacts download` is the simplest option and obeys both `MLFLOW_TRACKING_URI` and the S3 env vars:

```bash
mkdir -p "$DEST"
uv run mlflow artifacts download \
    --run-id "$RUN_ID" \
    --artifact-path "$ARTIFACT_SUBPATH" \
    --dst-path "$DEST"
```

This lands the artifacts at `$DEST/$ARTIFACT_SUBPATH/` (MLflow preserves the sub-path). The eval repo's `main.py` loads from a flat folder — e.g. `./models/uplift_correction/.../model.pkl` — so flatten one level:

```bash
mv "$DEST/$ARTIFACT_SUBPATH/"* "$DEST/"
rmdir "$DEST/$ARTIFACT_SUBPATH"
```

You should then see, inside `$DEST`:

```
MLmodel
model.pkl
conda.yaml
python_env.yaml
requirements.txt
input_example.json
serving_input_example.json
```

which matches the layout of the existing `uplift_correction_15022026_d22c11257e7d4bad85f4108d4f3b0e09/` folder that `main.py` currently points at.

### Alternative: Python API (if the CLI flattens oddly)

```bash
uv run --with mlflow python - <<PY
import mlflow
mlflow.artifacts.download_artifacts(
    run_id="950267949ce44f4db686d0692a4d4d4f",
    artifact_path="uplift_correction",           # <-- confirm sub-path
    dst_path="models/uplift_correction/uplift_correction_<DDMMYYYY>_950267949ce44f4db686d0692a4d4d4f",
)
PY
```

---

## 4. Pull the companion route-mean lookup (if this run logged one)

`uplift-order-predictor/main.py` also logs `route_mean_uplift_lookup.csv` as a top-level artifact (see `mlflow.log_artifact(lookup_path)`). If the eval uses it, grab it next to the model:

```bash
uv run mlflow artifacts download \
    --run-id "$RUN_ID" \
    --artifact-path route_mean_uplift_lookup.csv \
    --dst-path "$DEST"
```

(skip if `list_artifacts` in step 2 didn't show it).

---

## 5. Point the evaluation at the new model

In `flt-test-uplift-prediction/main.py` around line 118 you have:

```python
correction_model_path = "./models/uplift_correction/uplift_correction_15022026_d22c11257e7d4bad85f4108d4f3b0e09/model.pkl"
```

To run the comparison, swap it (or add a CLI flag) to the newly-pulled folder:

```python
correction_model_path = "./models/uplift_correction/uplift_correction_<DDMMYYYY>_950267949ce44f4db686d0692a4d4d4f/model.pkl"
```

Then run the eval as per the repo README:

```bash
uv run python main.py
```

To A/B the two, run once with each path, save the `output/uplift_results_all_months.xlsx` under a different name between runs, and diff.

---

## 6. Sanity checks after pull

- `cat "$DEST/MLmodel"` — the `run_id:` field should equal `950267949ce44f4db686d0692a4d4d4f`.
- `python -c "import joblib; m = joblib.load('$DEST/model.pkl'); print(type(m), getattr(m, 'feature_names_in_', None))"` — feature list should match what the eval's correction-loading code expects (see `main.py` line 815: `models["uplift_correction"].feature_names_in_`).
- If feature names differ between the two runs, the eval will raise at `models["uplift_correction"].predict(X_df)` (line 831) — that's the signal that the training-time features changed.

---

## 7. Gotchas

- **Wrong endpoint**: if `MLFLOW_S3_ENDPOINT_URL` is unset you'll get an AWS SigV4 error trying to hit real S3. Always source `mlflow_envs.sh` first.
- **Artifact sub-path mismatch**: the folder on disk must end up flat (`model.pkl` at the top), so strip the MLflow-preserved sub-path as shown in step 3.
- **Don't overwrite** the existing `uplift_correction_hist_19032026_950267949...` directory without checking first — if that was already pulled from this same run, you're just re-downloading it.
- **Do not** commit large model binaries without checking the repo's `.gitignore` policy for `models/` first.
