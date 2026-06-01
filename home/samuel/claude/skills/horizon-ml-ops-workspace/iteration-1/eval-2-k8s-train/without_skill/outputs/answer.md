# Retraining `schedule-predictor-minutes` on the Kubernetes cluster (INT)

This walks you through submitting an MLflow run of the `schedule-predictor-minutes` project against the ESP **int** Kubernetes cluster and the **int** MLflow tracking server.

---

## 1. Prerequisites — set these up first

### 1.1 kube context
The backend config `espint.json` in the horizon repo references the kube context `espint`:

```json
{
  "repository-uri": "esp-cr.artifactory.lsyesp.lhgroup.de/flt/horizon",
  "kube-job-template-path": "k8s_job_template.yaml",
  "kube-context": "espint"
}
```

Verify your `~/.kube/config` actually has a context named `espint` and that you can reach the cluster:

```bash
kubectl config get-contexts | grep espint
kubectl --context=espint -n flt-ramp get pods
```

If the context is missing or the namespace call fails, fix your kubeconfig before anything else — `mlflow run --backend kubernetes` will pick that context up via the `--backend-config` flag.

### 1.2 Docker login to the ESP container registry
The MLproject uses `docker_env`, so MLflow will build an image from `docker.io/datatactics/mlrunner:v1.1.3` and push it to the repo in `espint.json` (`esp-cr.artifactory.lsyesp.lhgroup.de/flt/horizon`). You need to be logged in locally:

```bash
docker login esp-cr.artifactory.lsyesp.lhgroup.de
```

(credentials are your Artifactory creds)

### 1.3 Python environment with MLflow + kubernetes client
Use the repo's existing venv — it already has everything from `requirements.txt` including `mlflow`, `kubernetes==30.1.0`, `boto3`:

```bash
cd /home/samuel/projects/flt/horizon
source venv/bin/activate
```

(You have `uv` available too, but the existing venv is already populated, so just source it.)

Sanity check:

```bash
mlflow --version
python -c "import kubernetes, boto3; print('ok')"
```

### 1.4 MLflow tracking creds — **INT**, not prod
Your `/home/samuel/projects/flt/mlflow_envs.sh` is pointed at **prod**. Do **not** source it as-is. Per the horizon README, for INT export:

```bash
export MLFLOW_TRACKING_URI=https://int.lsyesp.lhgroup.de/flt/mlflow/
export MLFLOW_TRACKING_USERNAME=admin
export MLFLOW_TRACKING_PASSWORD=dtacs4flt
```

These env vars must be set in the same shell where you run `mlflow run`, because — per the README — the tracking password is **not** propagated automatically into the kube Job; it's pulled from the `mlflow-env` secret referenced in `k8s_job_template.yaml` (`envFrom: secretRef: name: mlflow-env`) on the cluster side, and the tracking URI/username come from your local shell at submit time.

You likely also want the Minio (S3 artifact store) creds in the shell. The prod file has these but the INT cluster uses its own Minio behind the cluster — the kube job's `mlflow-env` secret on `flt-ramp` already carries `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `MLFLOW_S3_ENDPOINT_URL` into the pod, so locally you only strictly need the three `MLFLOW_TRACKING_*` vars above for the submit call.

---

## 2. The command

From the **horizon repo root** (not from inside the subdir — `mlflow run` takes the project dir as an argument):

```bash
cd /home/samuel/projects/flt/horizon
mlflow run schedule-predictor-minutes \
  --experiment-name schedule-predictor-minutes \
  --build-image \
  --backend kubernetes \
  --backend-config espint.json
```

What each flag does:
- `schedule-predictor-minutes` — path to the MLproject subdir.
- `--experiment-name schedule-predictor-minutes` — MLflow experiment to log the run under (create it beforehand in the MLflow UI if it doesn't exist yet, or MLflow will create it on the fly).
- `--build-image` — MLflow builds the docker image locally from the project's `docker_env` and pushes it to the registry in `espint.json` before submitting the Job.
- `--backend kubernetes` — use the k8s backend.
- `--backend-config espint.json` — picks the `espint` kube context, the `flt/horizon` image repo, and `k8s_job_template.yaml` as the Job spec.

### Overriding training parameters (optional)

The `MLproject` entry point exposes three parameters with defaults matching the mid-range config:

| param           | default | meaning                              |
|-----------------|---------|--------------------------------------|
| `days_min`      | 91      | min days-to-ops window              |
| `days_max`      | 220     | max days-to-ops window              |
| `bias_features` | `false` | whether to include bias features    |

To override (example: short horizon 1–90 with bias features), pass `-P`:

```bash
mlflow run schedule-predictor-minutes \
  --experiment-name schedule-predictor-minutes \
  --build-image \
  --backend kubernetes \
  --backend-config espint.json \
  -P days_min=1 -P days_max=90 -P bias_features=true
```

---

## 3. After you submit

- MLflow prints a run id and, because the backend is kubernetes, launches a Job in namespace `flt-ramp` on the `espint` cluster.
- Watch the job:

  ```bash
  kubectl --context=espint -n flt-ramp get jobs --sort-by=.metadata.creationTimestamp | tail
  kubectl --context=espint -n flt-ramp logs -f job/<job-name>
  ```

- Follow progress in the INT MLflow UI: https://int.lsyesp.lhgroup.de/flt/mlflow/ under experiment `schedule-predictor-minutes`.

---

## Quick checklist before you hit enter

- [ ] `kubectl --context=espint -n flt-ramp get pods` works
- [ ] `docker login esp-cr.artifactory.lsyesp.lhgroup.de` done in this shell
- [ ] `source /home/samuel/projects/flt/horizon/venv/bin/activate`
- [ ] `MLFLOW_TRACKING_URI`, `MLFLOW_TRACKING_USERNAME`, `MLFLOW_TRACKING_PASSWORD` exported for **int** (not sourced from `mlflow_envs.sh`, which is prod)
- [ ] `cwd` is `/home/samuel/projects/flt/horizon`
- [ ] Then run the `mlflow run schedule-predictor-minutes ...` command above
