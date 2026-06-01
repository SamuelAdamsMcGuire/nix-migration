---
name: User handles git push and ArgoCD sync on infra repos
description: For repos that ArgoCD watches (vigilo-services, fraalliance, etc.), do code changes and commits only — never push or trigger Argo sync; user does both manually
type: feedback
originSessionId: 83ed94d5-4964-4800-bbbf-21297e2ae18e
---
For Kubernetes/infra repos that ArgoCD watches (e.g. `vigilo-services`, `fraalliance`-related GitOps repos), do code changes and local commits only. Do NOT `git push` and do NOT trigger any ArgoCD sync — the user handles both manually.

**This also applies to `fraalliance-gui` (the platform GUI app source).** Even though it's an application repo (not pure GitOps manifests), the user wants to control pushes manually for this one — auto-build/deploy pipelines pick up pushes. Confirmed 2026-05-07 after I auto-pushed deploy fixes on the `migrate-fastapi-keep-metrics` branch.

**Why:** Pushing to these repos = deploying, because ArgoCD auto-pulls. The user wants explicit control over what reaches dev/int/prod and when each environment gets synced. Stated 2026-04-28 during the spilo Endpoints cleanup (vigilo-services repo).

**How to apply:** This *overrides* the global "always push after committing" preference, but only for infra/GitOps repos. For application code repos (e.g. ML training repos under `~/projects/flt`), the global "always push" still applies. If unsure whether a repo is GitOps-watched, ask before pushing. Stop short of `git push` in these repos and don't run `kubectl` commands that trigger sync (e.g. patching Argo Application annotations, `argocd app sync`).
