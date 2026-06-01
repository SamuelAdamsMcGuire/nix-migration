---
name: Parked items review
description: Auto-extracted candidates from past Claude sessions — review, then promote real ones to actionable - [ ] items
type: project
---

# Parked candidates from past Claude sessions (3)

_Generated 2026-05-09 21:05 by `scan-parked-items`._  
_Each block below is a moment where you said something like "park this / for later / do later". They are NOT yet aggregated into `~/todo.md` — only `- [ ]` lines in this file are._

**To process a candidate:** read it, decide if it's still real. If yes, write a `- [ ]` item under "Confirmed parked items" at the bottom. Then delete the candidate block. If no, just delete it. Survivors flow into `todo.md` on next `refresh-todo`.

---

## Candidates

### 2026-05-06 — session `cebd8c6c` (project `-home-samuel-projects-fraalliance-fraalliance-pfa`)
**Trigger:** "another day"  
**You said:** The collectors have been runing since yesterday - should we take a look and see what we have or do we need to waiting another day. The new Platform website has not be released yet. Can the scraper stay as is when it is released or does it also need changes  
**Preceding context:** Schönen Feierabend! 🍻  Solid day's work — INT and PROD live with all four collectors, schema cleaned up, customer docs ready, FastAPI branch staged for tomorrow's reviewer. The 4-month flatline is now per-app, per-company, per-day data flowing into Superset. Not bad for one session.  Bis morgen.

### 2026-04-28 — session `3e7f485c` (project `-home-samuel-projects-flt`)
**Trigger:** "another time"  
**You said:** I think we leave this for another time.   Are all of the other changes documented in the respective readmes  
**Preceding context:** Quick reality check first: **history rewrite without rotation is cosmetic.** Anyone who already cloned these repos (or had access to the Forgejo backend cache, CI runners, etc.) still has the values. So the order matters: rotate when stakeholders allow, history rewrite is the cleanup that follows.  That said, for the rewrite itself — here's the playbook.  # Tool: `git filter-repo`  Modern replacement for `filter-branch` (which is deprecated and slow). It's the tool the git project itself recommends now. Two reasons it fits this job:  - **`--replace-text expressions.txt`** redacts specific stri…

### 2026-04-28 — session `3e7f485c` (project `-home-samuel-projects-flt`)
**Trigger:** "parked"  
**You said:** taxi in is parked - I would not worry about it  I say we can also skip 2 for now. Does this have the same issue?  k --context=espprod -n flt-ramp describe secrets dbt-service-env-cmh658mm8d            ok  5s  local-k8s kube  13:50:14  Name:         dbt-service-env-cmh658mm8d Namespace:    flt-ramp L…  
**Preceding context:** # Findings summary  ## ✅ Both clusters have what we need for PROD and INT  **espprod** `dbt-biz-env-tf46tc22k8`: - `DBT_ENV_SECRET_FLT_PW = VU2gq_yF` ← matches main.py - `DBT_ENV_SECRET_FUEL_PW = i6AqT!9xR` ← matches main.py - `DBT_ENV_SECRET_MVT_PW = MVTuser123_PROD` ← matches main.py  **espint** `dbt-biz-env-d59m52mcm6`: - `DBT_ENV_SECRET_MVT_PW = MVTuser123_INT` ← matches the value in `horizon/README.md` - `DBT_ENV_SECRET_FLT_PW = nf8n_XLj` ← *new info, the code doesn't use this today* - `DBT_ENV_SECRET_FUEL_PW = hzvNh4kl.b` ← *new info, the code doesn't use this today*  So when we refactor…

---

## Confirmed parked items

_Add `- [ ]` items here as you process candidates above. These get pulled into `~/todo.md`._

