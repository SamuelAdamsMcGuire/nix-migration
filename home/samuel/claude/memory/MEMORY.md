# fraalliance-pfa project notes

## Cert automation (parked)
Init container approach for auto-building truststore at pod startup — no static JKS in repo.
See: `memory/cert-init-container.md`

## GET body issue (parked)
REST endpoints use GET with JSON body (works in jetty/1.2.3, breaks in undertow/1.3.0).
Integration environments reverted to 1.2.3 until consumers can be updated.
Needs coordination with API consumers to switch to POST or query params.

## Public API URLs
- [fraalliance API URLs](reference_fraalliance_api_urls.md) — INT/PROD hostnames + `{{REST_CONTEXT_PATH}}` resolves to `/fraalliance/api`

## LH cute.dlh.de gateway User-Agent filter
- [LH UA filter](project_lh_cute_user_agent_filter.md) — LH blocks Apache-HttpClient/* UAs with 500; set `User-Agent: curl/X.Y.Z` in Camel routes hitting `*.cute.dlh.de`

## Camel chained HTTP cleanup
- [Camel chained HTTP](feedback_camel_chained_http_cleanup.md) — wipe headers + body between `<to>` calls; use `CamelHttpMethod` header, not `?httpMethod=` URI param

## User-metrics scraper — known empty/low-traffic sources
- [User-metrics scraper state](project_user_metrics_scraper_state.md) — ODD intentionally not connected (needs OAUTH2); pfa_gui genuinely low-usage. Treat as expected, not collector bugs

## Landingpage FastAPI migration — INT deploy gotchas
- [Landingpage FastAPI INT gotchas](project_landingpage_fastapi_migration.md) — BASE_PATH (no trailing slash), FAB_REACT_CONFIG.sso as string not list, fixed redirect_url not factory, GUNICORN_CMD_ARGS for proxy headers, app/__init__.py silent from_pyfile

# FLT project — Phase 1 status (2026-02-26)
- Best models: all Feb 15 (see `flt_phase1_improvement_backlog.md` for WAPE scores + improvement backlog)
- Chart: `flt-test-uplift-prediction/output/phase1_comparison.html` — regenerate with `uv run python generate_phase1_chart.py`
- Benchmark script: `benchmark_phase1_models.py` (update ACTIVE_* paths if models change)
- Clean training data: `data/train_10airports_220_clean.csv` — retraining on it alone made things worse

# FLT — items to investigate

## Unscheduled flight prediction via historical route seeding
Currently unclear how XQ-KEF (0 scheduled, 2 actual, 2 predicted) works in practice.
Hypothesis: test vector is built from historically observed (airline, airport, seat_bin) combos, not just the live schedule — routes not in the current schedule get a row with scheduled_deps=0 and the delta model predicts the positive delta.
**To investigate:** how does `create_test_vector_10airports.py` build its input? Does it seed from historical routes or purely from the schedule? If purely from the schedule, unscheduled flight prediction may not actually work as the slide claims.
Potential improvement: always include all historically observed routes with scheduled=0 as a floor, so the model can catch routes that operate off-schedule.

# FLT presentation — pending branding
Awaiting company logo + brand colours to finalise template. See `memory/flt_presentation_pending.md`.

# datatactics — business / sales
- [Arvana outbound evaluation](project_arvana_outbound_evaluation.md) — Berlin B2B outbound agency met 2026-05-20. €2k/mo LinkedIn, €3k/mo +email. Reputable but SaaS-focused. Recommended 3-mo pilot + internal spike.

# NixOS migration (Manjaro → NixOS, started 2026-05-29)
- [NixOS migration](project_nixos_migration.md) — backup bundle DONE & verified at `~/nixos-migration-backup.tar.zst.gpg` (gpg AES-256). Next: Step 2 package/toolchain inventory → NixOS config

# Workstation / network
- [STARTPLATZ WiFi](reference_startplatz_wifi.md) — 2.4 GHz channel 6 heavily congested; profile locked to 5 GHz (`band=a`). If "internet issues" recur at STARTPLATZ, check that lock is still in place before re-diagnosing

# ~/todo.md
- [Tracker mirror autogen](reference_todo_md_autogen.md) — `## Tracker mirror` block is managed by `refresh-todo` (Trackspace + Deck). Don't hand-edit between AUTOGEN markers

# Git preferences
- Always push after committing — no need to ask (EXCEPT on GitOps/infra repos: see [Infra push/sync](feedback_infra_push_sync.md))
- [flt.conf SSH personal override](feedback_flt_ssh_personal_override.md) — ~/.ssh/config.d-dtacs/flt.conf has a deliberate uncommitted edit (u119230 + %% escaping) on a SHARED team repo; never commit/push it, treat as personal override
- Commit messages: minimal, no co-author line
- [Infra push/sync](feedback_infra_push_sync.md) — on Argo-watched repos (vigilo-services, fraalliance) commit only; user handles push + Argo sync
- [Secret cleanup workflow](feedback_secret_cleanup_workflow.md) — for security/secret-removal tasks: ask before every change, never push, user pushes themselves

# Repo structure under ~/projects/flt
`flt/` is NOT a git repo — it's just a folder.
Each subdirectory is its own independent git repo (e.g. `horizon/`, `flt-test-uplift-prediction/`).
Always use `git -C /home/samuel/projects/flt/<subdir>` for git commands, never `git -C /home/samuel/projects/flt`.
