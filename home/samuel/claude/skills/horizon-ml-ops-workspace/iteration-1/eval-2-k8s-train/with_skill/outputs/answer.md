# Retrain `schedule-predictor-minutes` on the Kubernetes cluster (int)

This uses the `horizon-ml-ops` skill's helper script (`scripts/horizon_models.py`), which wraps `mlflow run` with the correct tracking-server env vars and the `espint.json` backend-config, then shells out to `mlflow run <subproject> --build-image --backend kubernetes --backend-config espint.json`.

Your layout matches the skill's defaults (`FLT_ROOT=~/projects/flt`, `HORIZON_DIR=~/projects/flt/horizon`, creds at `~/projects/flt/mlflow_envs.sh`), so no path env vars need overriding.

---

## 1. Prerequisites (one-time / per-shell)

### 1a. Confirm the credentials file exists and is complete

The script auto-loads `/home/samuel/projects/flt/mlflow_envs.sh`. For a `train` call you only strictly need:

```sh
export MLFLOW_TRACKING_PASSWORD=...
```

If it's missing, the script exits with a clear error pointing at the search paths. (The AWS/Minio keys in that file are only required for `pull`, not `train`, but it's fine if they're already in there.)

Quickly sanity-check:

```bash
grep MLFLOW_TRACKING_PASSWORD /home/samuel/projects/flt/mlflow_envs.sh
```

### 1b. Log in to the container registry (required for `--k8s`)

The `--k8s` flag triggers `mlflow run --build-image`, which pushes the training image to the ESP registry. You must be logged in **in the current shell session** before running the command:

```bash
docker login esp-cr.artifactory.lsyesp.lhgroup.de
```

Use your LH / Artifactory credentials. Skipping this is the most common cause of a `--k8s` run failing during the image build step.

### 1c. Confirm your `kubectl` context points at the int cluster

`mlflow` submits the job via whatever kubeconfig context is currently active. Verify:

```bash
kubectl config current-context
kubectl get ns        # should list the flt int namespaces without auth errors
```

Switch context if needed (`kubectl config use-context <int-context-name>`) before submitting.

### 1d. Make the helper script convenient to call

The script has a PEP 723 inline-dependency header and the shebang `#!/usr/bin/env -S uv run --script`, so with `uv` already installed there is no venv activation and no pip install — first call downloads `mlflow` into uv's cache (~30s), subsequent calls are instant.

Set up the alias for this shell:

```bash
alias hmo="$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py"
```

(Add it to `~/.zshrc` if you want it permanent.)

**Fallback if you'd rather not use uv:** activate the horizon venv and invoke via `python`:

```bash
cd /home/samuel/projects/flt/horizon
source venv/bin/activate
python "$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py" train schedule-predictor-minutes --k8s --env int
```

---

## 2. The command

`--env int` is already the default, so the `--env int` flag is optional but worth being explicit:

```bash
hmo train schedule-predictor-minutes --k8s --env int
```

What that does under the hood:

- `cd`s into `/home/samuel/projects/flt/horizon`
- Sources `/home/samuel/projects/flt/mlflow_envs.sh` so `MLFLOW_TRACKING_PASSWORD` is available
- Exports `MLFLOW_TRACKING_URI=https://int.lsyesp.lhgroup.de/flt/mlflow/` and `MLFLOW_TRACKING_USERNAME`
- `exec`s:

  ```
  mlflow run schedule-predictor-minutes \
      --experiment-name schedule-predictor-minutes \
      --build-image \
      --backend kubernetes \
      --backend-config espint.json
  ```

### Overriding MLproject parameters

`schedule-predictor-minutes/MLproject` exposes three params with sensible defaults (`days_min=91`, `days_max=220`, `bias_features=false`). Everything after `--` is forwarded verbatim to `mlflow run`. Examples:

```bash
# Change the training window
hmo train schedule-predictor-minutes --k8s --env int -- -Pdays_min=120 -Pdays_max=300

# Enable bias features
hmo train schedule-predictor-minutes --k8s --env int -- -Pbias_features=true
```

No `-Pengine=...` is needed for this subproject — it is only required by subprojects that take a DB engine parameter.

---

## 3. After submission — watching the run

Once `mlflow run` returns (it prints the run_id and exits as soon as the k8s Job is submitted), you can:

- Watch the pod:
  ```bash
  kubectl get pods -w | grep schedule-predictor-minutes
  kubectl logs -f <pod-name>
  ```
- List your recent runs via the skill:
  ```bash
  hmo list schedule-predictor-minutes --env int
  ```
- Or open `https://int.lsyesp.lhgroup.de/flt/mlflow/` in the browser and jump to the `schedule-predictor-minutes` experiment.

When you later want to evaluate the trained model locally, use `hmo pull <run_id> --env int` — that drops it into `flt-test-uplift-prediction/models/mins/` with a `mins_<ddmmyyyy>_<run_id>` folder name, ready for `test.py`.
