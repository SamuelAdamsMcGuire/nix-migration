---
name: Landingpage FastAPI migration — INT deploy gotchas
description: Non-obvious config requirements that surfaced when getting the FastAPI-migrated landingpage to boot in INT
type: project
originSessionId: a0655bfd-9a17-4919-86ec-361b2eab632e
---
The `migrate-fastapi-keep-metrics` branch of `fraalliance-gui` ports landingpage from Flask → FastAPI. Pat (FastAPI guru) wrote the migration and tested locally via `python run.py` only — never as a container or in INT. Several non-obvious K8s/config issues had to be fixed in `fraalliance-platform/k8s/landingpage/espint/`:

**Why:** these are not in OneOps' config (because OneOps lives at host root, not under a sub-path) so they're easy to miss when porting.

**How to apply:** when extending to espdev / espprod, replicate the same config keys with env-specific URLs.

## Required config keys for landingpage (different from OneOps pattern)

1. **`BASE_PATH = "/fraalliance-platform/landingpage"`** (no trailing slash). fastapi-rtk substitutes this into `{{base_path}}` in index.html and sets `app.root_path`. Without it, SPA bootstraps with `<base href="/">` and JS bundle 404s. With trailing slash, you get `//` redirect loops.

2. **`FAB_REACT_CONFIG = {"sso": "api/v1/auth/login/fraalliance-platform"}`** — landingpage's SPA expects `sso` as a **plain string**, NOT OneOps' list-of-objects format. Using objects results in `[object Object]` showing up in the URL when clicking SSO.

3. **`OAUTH_PROVIDERS[*].redirect_url`** — use a fixed absolute URL, NOT the OneOps-style `redirect_url_factory` that derives from `Referer`. Browser navigation to the SSO endpoint sometimes doesn't include `Referer` (referrer-policy / SPA navigation patterns), causing the factory's referer-allowlist check to 403.

4. **`frontend.env`: `GUNICORN_CMD_ARGS=--forwarded-allow-ips=*`** — gunicorn defaults to trusting `X-Forwarded-Proto` only from `127.0.0.1`. Traefik isn't on localhost, so its `https` header is ignored and OAuth redirects come back as `http://`, breaking the flow.

## App-side change in fraalliance-gui

`app/__init__.py:14`: `g.config.from_pyfile('config.py', silent=True)` (silent flag added). The deploy uses `APP_CONFIG_PATH=/config.py` env var; without `silent=True`, the unconditional `from_pyfile('config.py')` looking in CWD blows up before the env-var override runs.

## 15-min scraper CronJob was suspended pre-migration

`user-metrics-scraper` (the legacy 15-min `scraper.py` that hits `/metrics` and writes to `user_metrics` / `app_clicks` / `company_user_metrics` in `spilo_landingpage`) was found `suspend: true` in INT — disabled around 2026-04-09 (~29 days before discovery), most likely as a temp measure during the FastAPI-migration prep that nobody re-enabled. Result: those three tables had no data from 2026-04-27 onwards even though the live `/metrics` endpoint was emitting correct values.

**To re-enable:** `kubectl patch cronjob user-metrics-scraper -p '{"spec":{"suspend":false}}'`. The daily collectors (which write to `app_users_daily`) were on a SEPARATE CronJob and not affected.

**If we see similar "data flow looks broken" symptoms in the future:** check `kubectl get cronjob -n fraalliance-platform` for `SUSPEND` column before assuming the app or scraper is broken.

## Login metrics: use OAuth on_before_login callback, NOT request middleware

For tracking landingpage's daily-login Redis counters (`per_day_users`, `daily_logins_gauge`, `daily_company_users_gauge`), call `track_login(user)` from inside `on_before_login_oidc` in the K8s `config.py` — NOT from a request middleware.

**Why the middleware approach fails (we tried it twice):**
- `request.state.user` is never populated by fastapi-rtk (Flask-era attribute)
- Switching to `g.user` *also* fails: `g` is a request-scoped contextvar set by fastapi-rtk's `set_global_user` dependency, and that dependency runs INSIDE fastapi-rtk's `GlobalsMiddleware`. By the time an outer `BaseHTTPMiddleware` does `await call_next(request)`, the inner contextvar has been torn down. Outer middleware always reads `g.user = None`.

**Why `on_before_login_oidc` works:** it fires inside fastapi-rtk's auth flow with a real user object, once per login. Idempotent Redis SADD dedups same-user-same-day. Fixed in DHFA-1102 (commit on `migrate-fastapi-keep-metrics`).

The `app_clicks` metric is independent of this — Socket.IO event handler writes Redis directly with the user-supplied button_id, no auth needed.

## Traefik strip-prefix is NOT compatible with this stack — DO NOT add it

`k8s/landingpage/espint/ingressroute.yaml` defines a `landingpage-stripprefix` Middleware but deliberately does NOT reference it in the Rule. Tempting to attach it (e.g. to fix Socket.IO at `/socket.io/`), but doing so 404s every static asset (`/static/*.js|.css`). Without strip-prefix, gunicorn-uvicorn's `SCRIPT_NAME` handling somehow gets static URLs to resolve correctly; with it, the StaticFiles mount stops matching. Root cause not fully understood, but the empirical answer is clear: leave the IngressRoute Rule with NO middlewares.

For Socket.IO to work on the prefixed URL, fix it app-side instead — set `socketio_path='/fraalliance-platform/landingpage/socket.io'` when creating `socketio.AsyncServer` in `fraalliance-gui/app/__init__.py`.

## Dockerfile fixes (committed on the gui branch)

- CMD: `gunicorn ... --worker-class=eventlet ... app:app` → `gunicorn ... --worker-class=uvicorn.workers.UvicornWorker ... app:socket_app`
- Build base: `node:lts-alpine3.23` → `node:lts-slim` (rollup native binary issue on musl)
- Python: 3.11 → 3.12 (fastapi-rtk uses PEP 701 multi-line f-strings)
- requirements.txt: pin `fastapi-rtk==1.1.1`, drop legacy `git+sqlalchemy-utils@0.38.3.1` fork, add `uvicorn[standard]`
- webapp/package.json: add `postcss-simple-vars` as a direct devDep (was transitive, broke isolated pnpm install)
