---
name: Secret-cleanup work — ask before every change, never push
description: For security/secret-removal work across repos, user reviews every change and pushes themselves
type: feedback
originSessionId: 3e7f485c-d3ca-447a-a0df-b7b3baf089f5
---
For security cleanup work (removing plaintext secrets, history rewrites, rotation, sops migrations), operate strictly step-by-step:

- Show the proposed change (diff or exact edit) and **wait for explicit approval before applying it**.
- After applying, do not `git push`. The user is the only one who pushes for these tasks.
- Apply one change at a time when reasonable; do not batch multiple file edits without checking in between.

**Why:** Plaintext-secret cleanup is high-stakes — a wrong edit can break running jobs, and force-pushes during history rewrites can lose work. The user wants a human in the loop on each step.

**How to apply:** This overrides the general "always push after committing" rule whenever the task is secret cleanup, history rewrite, sops/encryption migration, or anything touching credentials. It does not change behaviour for normal feature/refactor work.
