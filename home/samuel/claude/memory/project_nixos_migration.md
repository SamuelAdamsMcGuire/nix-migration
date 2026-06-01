---
name: project-nixos-migration
description: Company laptops migrating Manjaro → NixOS; pre-migration backup bundle status
metadata: 
  node_type: memory
  type: project
  originSessionId: d196af06-49fa-4518-b514-e69bd319ad32
---

Datatactics is migrating all company laptops from **Manjaro → NixOS** (started 2026-05-29). Goal: declarative, reproducible, version-controlled fleet configs.

**Pre-migration backup — DONE & verified (2026-05-29):**
- Encrypted bundle: `~/nixos-migration-backup.tar.zst.gpg` (4.3 MB, gpg symmetric AES-256, passphrase-protected)
- SHA-256: `c75b2043af81d242ee85d2a041a73c93aa68dee0e332da65d0a84d6ba8f371de`
- Cold-start decrypt verified (agent cache cleared first). Plaintext shredded; only the `.gpg` remains.
- Contains (HOME-relative, see `RESTORE-README.txt` inside): age key `.config/sops/age/keys.txt`; `.ssh/` (key `yes` + flt.conf override, see [[feedback-flt-ssh-personal-override]]); `.kube/config`; `.docker/config.json`; `.local/share/keyrings/` (GNOME Keyring — Trackspace PAT, Nextcloud app-pw, MinIO keys, see [[reference-todo-md-autogen]]); todo automation (`refresh-todo`, `open-todo.sh`, `scan-parked-items`, systemd user units, autostart, `todo.md`+`.bak`); `.zshrc`, `.p10k.zsh`, `.zsh_history`; `flt.conf.personal-override.patch`; `flight-positioning.bundle` (git bundle, all refs — preserves 5 local-only espint commits, tip 7f10bd1).
- `age` is NOT installed on Manjaro (only gpg+zstd) — that's why gpg symmetric, not age. gpg needs `export GPG_TTY=$(tty)` for pinentry to work.

**Git cleanup before backup (done):** ~10 own-repo unpushed branches pushed to remotes (Bucket A); 5 Argo-repo branches (Bucket B: test_pgbouncer, keystore-update, data_linage, sam, rahla_practice) consciously dropped — data_linage's lineage work was already on origin/main, its only delta was broken XML.

**User's outstanding manual steps:** copy `.gpg` to USB + Nextcloud, sha256-verify both, store passphrase off-machine.

**Inventory — DONE (2026-05-29):** full inventory written to `~/nixos-migration-inventory.md`. 240 pacman explicit (most are OS/desktop → NixOS modules, NOT packages); ~45 real user apps to port; 9 AUR; 1 brew (`mdbtools`); snap dropped. Toolchains: uv (primary py mgr), node25/pnpm, go, rust, jdk21, ruby — to be per-project devShells + direnv, not global. ⚠️ SECURITY: hardcoded VPN password in `~/.zshrc:115` (`vpn` alias pipes plaintext pw to sudo; world-readable; now also in backup) — move to sops/keyring + ROTATE on NixOS. TODO before wipe: `dconf dump /org/gnome/ > ~/gnome-settings-backup.dconf` (GNOME tweaks not yet in backup).

**Starter config — DONE (2026-05-29):** `~/nixos-config` (local git, no remote, commit 4d225d0). Modular flake: nixpkgs 25.11 + home-manager + sops-nix. Layout: `modules/` (common, desktop-gnome, networking, dev, users, secrets — shared fleet base), `hosts/samuel-21tb003mge/` (AMD ThinkPad; **hardware-configuration.nix is a PLACEHOLDER — must regenerate on target via nixos-generate-config**), `home/samuel/` (zsh full .zshrc translation, git, packages, direnv). Host = AMD Ryzen AI 7 PRO 350 / Radeon 860M, UEFI, ext4 nvme, hostname samuel-21tb003mge, tz Europe/Berlin, locale en_US.UTF-8, keymap de. age recipient in `.sops.yaml`: age1rc7pxe3e2j0pmc2cz83vgr75mq2av0z37whgny0j3feneun8rgps6k3kas.
- **NOT validated** — nix isn't installed on Manjaro, nothing `nix flake check`'d. First-build friction expected: some `gnomeExtensions.*` attr names, 25.11↔26.05 option drift.
- TODOs left as markers: copy restored `~/.p10k.zsh` → `home/samuel/p10k.zsh` (zsh.nix references it); create `secrets/secrets.yaml` when first secret needed.
- The config defines the whole MACHINE (OS/desktop/hw/boot/services/users/shell), not just packages. Backup bundle = data/secrets; config = machine; per-repo devShells = project toolchains.

**Cutover plan (set 2026-05-29):** physical backup Mon 2026-06-01, OS wipe Manjaro→NixOS Tue 2026-06-02.
- **Checklist:** `~/monday-migration-backup-checklist.md` (A re-capture state, B back up local-only nixos-config, C copy bundle to USB+Nextcloud, D prove restorable, E browser/2FA+cloud sync, F NixOS install USB).
- **One-shot rebuild script:** `~/rebuild-migration-backup.sh` — run Monday in a real terminal (`bash ~/rebuild-migration-backup.sh`). Re-captures fresh state, git-bundles BOTH flight-positioning AND ~/nixos-config (the latter is local-git-only, would otherwise be lost), dconf-dumps GNOME, refreshes flt.conf patch, tars + gpg-encrypts (prompts passphrase), verifies decrypt, shreds plaintext (won't shred if decrypt fails). Prints SHA-256 + copy/verify next steps. Syntax-checked, NOT yet run.
- Script automates checklist A+B; C/D/E/F stay manual. Bundle output overwrites `~/nixos-migration-backup.tar.zst.gpg` (Friday's hash c75b…f371de becomes stale once re-run).
- Still NOT covered by any automation: browser passwords/bookmarks/2FA export, NixOS install USB creation.

**Mon 2026-06-01 pre-prep done (wipe still TUE 06-02, prep that morning):**
- GNOME settings dumped → `~/gnome-settings-backup.dconf`; flt.conf patch refreshed; tooling verified (gpg/zstd/tar/dconf/shred/sha256sum all present).
- Fresh git scan caught new at-risk items beyond Friday: (a) `presentations` master had 1 unpushed commit ("remove redundant jenkins script") + DIVERGED remote (CI commits build/index.html to master) → preserved as NEW github branch `premigration-sam-backup` (did NOT force master); (b) uncommitted work in `dtacs-repos/skills` (spilo-to-cnpg SKILL.md + manifests.md) and `flight-positioning-service` (espint alert yaml) → snapshotted to `~/migration-dirty-patches/*.patch` and ADDED to rebuild script include list.
- KEY: rebuild script only git-bundles flight-positioning + nixos-config; ALL other repos rely on remotes, and git bundle does NOT capture uncommitted files — hence the patch approach for dirty trees.
- Still discarding (confirmed): tutorials/agent-irrops-test (no remote), Bucket B Argo branches.
- Drive sizing: bundle ~4.3MB; home dir 158G (projects 27G in git, .cache 14G, Downloads 12G disposable). Colleague's 78GB drive is ~18,000× more than enough for the selective bundle. Tomorrow: also eyeball ~/Downloads for anything irreplaceable.

**Loose ~/projects notes/data backed up (2026-06-01):** 913 non-git loose files (~1.1 GB incl. horn DB dumps + flt uplift_graveyard data) copied + sha256-verified (0 mismatches) to external drive `/run/media/samuel/586A-AC03/backups/projects-loose-2026-06-01/` (931 GB NTFS/exFAT drive, mounted). `SHA256SUMS.txt` manifest on drive. NOT in the gpg bundle (too big) — lives only on this drive + laptop source. Only genuine plaintext-credential exposure there: `horn/.env` (certs are public .cer, session.sql/sops low-risk). File list cached at `~/.projects-loose-filelist.txt`.

**NEXT options (none started):** per-repo `flake.nix` devShells for flt/horizon/fraalliance; fleet-ify (more hosts).
