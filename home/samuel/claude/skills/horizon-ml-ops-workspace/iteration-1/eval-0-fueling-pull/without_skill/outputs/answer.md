# Pulling fueling-duration run `ca30b35113ef429685724f7f62dbe73e` into `flt-test-fueling-duration`

The run was trained on **prod**, so you'll pull the artifact from the prod MLflow tracking server (whose artifact store is prod MinIO). The `flt-test-fueling-duration` test harness (`test.py`) just walks every sub-directory of `models/` and loads each one with `mlflow.pyfunc.load_model`, so all you need to do is drop the MLflow model directory into `models/` under a sensibly-named folder.

Under the hood, training in `horizon/fueling-duration-predictor/main.py` logs the fitted pipeline with `mlflow.sklearn.log_model(model, "model", ...)`, so the artifact path inside the run is just **`model`**.

---

## 1. Prerequisites

You already have these — just double-check:

- `horizon` repo at `/home/samuel/projects/flt/horizon`
- `flt-test-fueling-duration` repo at `/home/samuel/projects/flt/flt-test-fueling-duration`
- MLflow creds file at `/home/samuel/projects/flt/mlflow_envs.sh` (contains `MLFLOW_TRACKING_URI` pointing at **prod**, `MLFLOW_TRACKING_USERNAME`, `MLFLOW_TRACKING_PASSWORD`, plus `MLFLOW_S3_ENDPOINT_URL` and `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` for MinIO)
- `uv` installed
- Python `mlflow` client — either via `uv run` against the test repo's env, or a global install

Source the env file first (every shell that will talk to MLflow needs these):

```bash
source /home/samuel/projects/flt/mlflow_envs.sh
```

Verify the five env vars are set before continuing:

```bash
env | grep -E "^(MLFLOW_|AWS_)"
```

The file already points at **prod** (`https://prod.lsyesp.lhgroup.de/flt/mlflow/`) — which matches where the run was trained. Don't re-point it at int or the download will 404.

---

## 2. Pick a target folder name

The test repo's naming convention (see its `README.md` and the existing entries in `models/`) is:

```
duration_<time|notime>_<xgb|light|hist>_<ddmmyyyy>_<run_id>
```

- `time` / `notime` — whether a time-of-day feature was used. The current fueling-duration-predictor on `main` drops `fueling_hour` but keeps `departure_hour`; existing March entries are labelled `notime`, so keep that label for consistency unless you want to distinguish the `departure_hour` variant yourself.
- Algorithm: `xgb`, `light`, or `hist`. Infer from the run's parent/child name in the MLflow UI, or from the `MLmodel` file once downloaded (the sklearn pipeline's final estimator gives it away).
- Date: the training-cutoff or run date in `ddmmyyyy` form (today would be `22042026`).
- The full 32-char `run_id` is appended so that the folder name is unique.

For this run the folder name should be something like:

```
duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e
```

(Adjust the algorithm token if this run is LightGBM or HistGradientBoosting instead of XGBoost.)

---

## 3. Pull the artifact with the MLflow CLI

From the test repo:

```bash
cd /home/samuel/projects/flt/flt-test-fueling-duration
source /home/samuel/projects/flt/mlflow_envs.sh

mlflow artifacts download \
  --run-id ca30b35113ef429685724f7f62dbe73e \
  --artifact-path model \
  --dst-path models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e
```

`mlflow artifacts download` writes the artifact into `<dst-path>/<artifact-path>`, so the command above produces:

```
models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e/model/
    MLmodel
    model.pkl
    conda.yaml
    python_env.yaml
    requirements.txt
    input_example.json
    serving_input_example.json
```

`test.py` expects `MLmodel` at the **top** of each model folder (it walks immediate sub-directories of `models/`), so flatten the extra `model/` layer:

```bash
cd models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e
mv model/* .
rmdir model
```

(If you prefer the one-liner alternative, use `mlflow artifacts download ... --dst-path <tmp>` then `mv <tmp>/model <models/<final-name>`.)

### Alternative: Python one-shot

If the CLI isn't on your PATH, this does the same thing and puts the files directly where you want them:

```bash
cd /home/samuel/projects/flt/flt-test-fueling-duration
source /home/samuel/projects/flt/mlflow_envs.sh

uv run python - <<'PY'
import mlflow
mlflow.artifacts.download_artifacts(
    run_id="ca30b35113ef429685724f7f62dbe73e",
    artifact_path="model",
    dst_path="models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e",
)
PY
```

You still need the post-download `mv model/* . && rmdir model` step because `download_artifacts` preserves the `model/` prefix.

---

## 4. Sanity-check the download

```bash
ls models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e
```

You should see at least `MLmodel` and `model.pkl`. Peek at `MLmodel` to confirm `run_id: ca30b35113ef429685724f7f62dbe73e` and the sklearn flavor — and to read the input schema (which tells you which algorithm it is if the folder name is ambiguous).

---

## 5. Run the evaluation

```bash
cd /home/samuel/projects/flt/flt-test-fueling-duration
uv sync    # only needed the first time, or after pyproject.toml changes
uv run python test.py --csv data/fueling_test_data_wallclock_18032026.csv
```

To test just the new model instead of comparing against every folder in `models/`:

```bash
uv run python test.py \
  --csv data/fueling_test_data_wallclock_18032026.csv \
  --model models/duration_notime_xgb_22042026_ca30b35113ef429685724f7f62dbe73e
```

Optional outputs:

```bash
# Save text report
uv run python test.py --csv data/fueling_test_data_wallclock_18032026.csv \
  --output results/ca30b35_eval.txt

# Save per-segment CSV
uv run python test.py --csv data/fueling_test_data_wallclock_18032026.csv \
  --output-csv results/ca30b35_eval.csv
```

---

## 6. Troubleshooting

- **`mlflow.exceptions.MlflowException: API request ... 401`** — you didn't `source mlflow_envs.sh`, or you sourced it in a different shell.
- **`botocore ... NoCredentialsError` / S3 403** — `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `MLFLOW_S3_ENDPOINT_URL` are missing. Re-source `mlflow_envs.sh`.
- **`RESOURCE_DOES_NOT_EXIST: Run ... not found`** — you're talking to the wrong tracking server. Confirm `echo $MLFLOW_TRACKING_URI` shows `prod.lsyesp.lhgroup.de`, not `int`.
- **`test.py` loads the model but predictions all look like 0** — you forgot to flatten the `model/` subfolder; `test.py` tried to load the parent dir (which has no `MLmodel`) and silently skipped it. Check the logger warnings at the top of the output.
- **Column-mismatch errors in `predict`** — `test.py` pads missing columns with 0.0 (or `num_trucks=1`), so a plain schema mismatch won't crash; but if the new model introduced an entirely new feature that isn't derivable from the test CSV, you'll need to update `prepare_data` in `test.py`.
