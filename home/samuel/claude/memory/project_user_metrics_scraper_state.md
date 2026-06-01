---
name: User-metrics scraper — known empty/low-traffic sources
description: ODD + pfa_gui appear empty/sparse in app_users_daily by design, not a bug
type: project
originSessionId: a0655bfd-9a17-4919-86ec-361b2eab632e
---
`fraalliance-user-metrics-scraper/scraper/collect_daily.py` writes per-app daily user counts into `spilo_landingpage.app_users_daily`. **Deployed ~2026-05-04** (collectors are new). Earlier rows in the table come from `--backfill-days` runs: Superset can backfill from its `logs` table; FAB apps (oneops, pfa_gui) only produce rows after two consecutive snapshots exist, so they only appear from ~May 4 forward.

Two sources legitimately look empty/sparse:

**ODD — not yet connected.** Collector is deployed but ODD is not running with `AUTH_TYPE=OAUTH2`, so the `_session_log` trigger never fires. The collector returns 0 rows by design. No investigation needed until ODD is switched to OAUTH2.

**pfa_gui — genuinely low-usage.** As of 2026-05-07 there was 1 row total in `app_users_daily` for `app='pfa_gui'`. Snapshot+diff pattern is healthy; the platform just isn't used much yet. Compare to `oneops` which sees ~15 users/day.

**Why:** prevents wasting time re-diagnosing these as collector failures every time we look at the data.

**How to apply:** when reviewing `app_users_daily`, treat ODD-empty and pfa_gui-sparse as expected. Focus diagnostics on `oneops` and `superset:*` rows instead.
