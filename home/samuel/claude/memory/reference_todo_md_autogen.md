---
name: ~/todo.md autogen tracker mirror
description: ~/todo.md has auto-managed Tickets blocks per project — never type inside them
type: reference
originSessionId: ea41eccf-6a71-4d4e-85dd-fb02b4748dde
---
`~/todo.md` mixes auto-managed ticket blocks with hand-written notes. Tickets are grouped **per project**, not in one mirror block.

**Layout (top → bottom):**
- `# Todos DD.MM.YYYY:` title (date rewritten at login by the wrapper)
- `### Open tasks issues` — USER'S manual daily-notes zone, never touched by the script. This is where the user adds "work done today / open items".
- `## Other tickets` → `### Tickets` — auto: unmapped Trackspace/Deck items, force-placed just below the manual top zone (before the first mapped project).
- `## Parked from Claude sessions` → `### Items` — auto, only present when parked items exist.
- One `## <Project>` per mapped project (Fraalliance, Flightpos, Vigilo, FLT), each with a `### Tickets` block at its top. Fraalliance also has `#### Tickets` blocks nested under `### OneOps/PFA/USSP/ODD` (Deck boards).
- Trailing `## Other`, `## Reference` etc. — manual.

**CRITICAL:** every `### Tickets` / `#### Tickets` block is overwritten on each run. Manual notes must go OUTSIDE them (e.g. under `### Open tasks issues`, or under non-`Tickets` subheadings like `#### INT`, `#### GENERAL`). Typing inside a Tickets block = erased on next refresh.

**Aggregation script:** `~/.local/bin/refresh-todo` (Python, stdlib only)
- Project→tracker routing is the `MAPPING` dict at the top of the script. To add/move a project, edit MAPPING and add a matching `## <Project>` heading.
- Trackspace (Jira DC `trackspace.lhsystems.com`): assignee=currentUser, unresolved, excludes Epics. Bearer PAT auth. GET `/rest/api/2/search`.
- Nextcloud Deck (`cloud.datatactics.de`): cards assigned to `s.mcguire`, active boards, skips stacks named done/archive/templates. Basic-auth app password.
- One source failing (e.g. Trackspace 302/timeout) writes "_fetch failed_" in just that block; the other source still updates. Don't run a refresh while Trackspace is down or it overwrites good ticket lists with "fetch failed".
- `normalize_blank_lines()` runs on every write: collapses 2+ blank lines to one (fence-aware, preserves code blocks), trims edges. This fixed a blank-line accumulation bug where `splice_section_at_top` leaked a blank line per run, growing a whitespace gap below the top notes.
- Backs up previous file to `~/todo.md.bak` on each change.

**Triggers:** ONLY (1) login via `~/.local/bin/open-todo.sh` (autostart wrapper — rewrites the date, refreshes once, THEN opens Typora), and (2) manual `refresh-todo`. The hourly systemd timer was REMOVED (2026-05-29): firing a rewrite into an already-open Typora made the editor reload and discard unsaved notes. Never re-add a recurring refresh. When refreshing manually, save in Typora first, then run `refresh-todo`, then let Typora reload.

**Credentials in GNOME Keyring:**
- `service=jira host=trackspace.lhsystems.com field=pat` — created at https://trackspace.lhsystems.com/secure/ViewProfile.jspa
- `service=nextcloud host=cloud.datatactics.de field={username,app_password}`
- `service=minio host=s3.datatactics.de field={access_key,secret_key}` (separate, for Dask work)

**Parked-items convention:**
- When the user defers something in conversation ("park this", "do later"), save `parked_<name>.md` in `~/.claude/projects/-home-samuel/memory/` with `- [ ]` line(s). `refresh-todo` picks up every `- [ ]` line in any `parked_*.md` and renders under `## Parked from Claude sessions`.
- One-shot scanner `~/.local/bin/scan-parked-items` (run once 2026-05-09 — low base rate, mostly false positives).
