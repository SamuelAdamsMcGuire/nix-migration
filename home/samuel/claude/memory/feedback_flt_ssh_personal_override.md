---
name: feedback-flt-ssh-personal-override
description: ~/.ssh/config.d-dtacs/flt.conf has a deliberate uncommitted personal override — never commit/push it
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d196af06-49fa-4518-b514-e69bd319ad32
---

`~/.ssh/config.d-dtacs` is a **shared team** SSH config repo (`github.com:dttctcs/config.d-dtacs`). Its committed `flt.conf` uses the team account `u839862` (added by Matthias Leinweber, 2023).

Samuel keeps a **deliberate, long-lived uncommitted edit** to `flt.conf` (mtime 2025-09-08): swaps the PAM jump-host user to his own account `u119230` and escapes `%` → `%%` (literal percent in the PAM proxy username, otherwise SSH treats it as a token). This is a *personal override of a shared config* and was intentionally never committed.

**Why:** committing/pushing it would overwrite `u839862` for the whole team. A dirty working tree here is the intended state, not forgotten WIP.

**How to apply:** never `git commit`/`git push` this file's change. Preserve it as a working-tree override (it rides along when `~/.ssh` is backed up) or as `~/flt.conf.personal-override.patch` to re-apply after a fresh clone. The `%%` escaping fix could be proposed to the team separately, but never bundled with the username swap. General rule: treat small deliberate uncommitted deltas in shared repos as personal overrides — back them up, don't push them.
