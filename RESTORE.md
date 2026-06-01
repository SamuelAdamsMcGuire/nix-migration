# 🔄 Post-migration RESTORE checklist (Manjaro → NixOS)

Follow top to bottom. Three sources feed this restore:
- **🔐 Bundle** — `nixos-migration-backup.tar.zst.gpg` (on the USB drive + Nextcloud). gpg AES-256, your passphrase.
- **💽 Drive** — `…/586A-AC03/backups/work_backup_pre_nix_01062026/` (projects notes, tutorials, claude tar).
- **📦 This repo** — `github.com/SamuelAdamsMcGuire/nix-migration` (the NixOS config itself).

> Order matters: **age key first** (everything secret depends on it), then the system build, then data, then apps.

---

## Phase 0 — Base NixOS installed
- [ ] NixOS installed from the USB, you can log in, network works (`ping github.com`).
- [ ] `git`, `gnupg`, `zstd` available (in the installer/base, or `nix-shell -p git gnupg zstd`).
- [ ] Plug in the USB drive; note its mount, e.g. `/run/media/$USER/<LABEL>`.

## Phase 1 — Decrypt & unpack the bundle
```bash
cd ~
cp /run/media/$USER/<LABEL>/<path>/nixos-migration-backup.tar.zst.gpg ~
export GPG_TTY=$(tty)
gpg --decrypt nixos-migration-backup.tar.zst.gpg | tar --zstd -xf - -C "$HOME"
```
- [ ] Bundle decrypted; you should now have `~/.config/sops/age/keys.txt`, `~/.ssh/`, `~/.kube/`, `~/.docker/`,
      `~/.local/share/keyrings/`, `~/.zshrc`, `~/Documents/`, `~/nixos-config.bundle`, etc. restored under `$HOME`.
- [ ] Fix perms if needed: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/yes ~/.config/sops/age/keys.txt`

## Phase 2 — Critical keys in place
- [ ] **age key**: confirm `~/.config/sops/age/keys.txt` exists (decrypts all cluster SOPS secrets — the keystone).
- [ ] **SSH key**: `ssh-add ~/.ssh/yes` works; `~/.ssh/config` + `config.d-dtacs/` present.
- [ ] **kubeconfig**: `~/.kube/config` present (`kubectl config get-contexts` after tools exist).
- [ ] **keyring**: `~/.local/share/keyrings/login.keyring` restored (holds git tokens, Trackspace PAT,
      Nextcloud, MinIO). Needs gnome-keyring running + your **same login password** to unlock.

## Phase 3 — Build the system from this repo
```bash
git clone https://github.com/SamuelAdamsMcGuire/nix-migration.git ~/nixos-config
cd ~/nixos-config
# Generate THIS machine's hardware config and replace the placeholder:
sudo nixos-generate-config --show-hardware-config > hosts/samuel-21tb003mge/hardware-configuration.nix
# (review it; ensure filesystems/boot match this disk)
sudo nixos-rebuild switch --flake .#samuel-21tb003mge
```
- [ ] Build succeeds. (First-build friction to expect: a couple of `gnomeExtensions.*` attr names, 25.11↔26.05 drift — fix per error messages.)
- [ ] Reboot into the new generation. GNOME + zsh + your packages should be live.
- [ ] **home-manager auto-restores Claude**: `~/.claude/CLAUDE.md` (symlink), and on first activation it
      seeds `skills/`, `settings*.json`, and **`memory/`** (writable). Verify `~/.claude/projects/-home-samuel/memory/MEMORY.md` exists.

## Phase 4 — Restore bulk data from the drive
```bash
D=/run/media/$USER/<LABEL>/backups/work_backup_pre_nix_01062026
mkdir -p ~/projects
rsync -rt "$D/projects/"  ~/projects/            # curated loose notes (verify against SHA256SUMS.txt)
rsync -rt "$D/tutorials/" ~/tutorials/           # incl. agent-irrops-test (no remote — only copy!)
tar --zstd -xf "$D/claude-full.tar.zst" -C ~     # full .claude fallback (only if Phase 3 seeding missed anything)
```
- [ ] Notes back under `~/projects/…`; verify a few against `SHA256SUMS.txt` on the drive.
- [ ] `~/tutorials/agent-irrops-test` restored (this one had **no git remote**).
- [ ] Re-clone the git-backed projects/tutorials from their remotes as needed (they weren't fully copied).

## Phase 5 — Git auth, VS Code, cloud tools
**Git auth** (helper is `libsecret`; keyring from Phase 2 should already carry the token):
- [ ] Test: `git -C ~/nixos-config push --dry-run`. If it prompts, re-enter the PAT from
      `~/Documents/git_password_save.txt` (it's stored there) — libsecret will cache it.

**VS Code** (config + 26 extensions are in this repo under `home/samuel/vscode/`):
```bash
mkdir -p ~/.config/Code/User
cp ~/nixos-config/home/samuel/vscode/settings.json    ~/.config/Code/User/
cp ~/nixos-config/home/samuel/vscode/keybindings.json ~/.config/Code/User/
cat ~/nixos-config/home/samuel/vscode/extensions.txt | xargs -L1 code --install-extension
```
- [ ] Extensions reinstalled (gitlens, ruff, python, jupyter, sqltools, apache-camel, claude-code, …).

**Cloud / CLI tools** (re-auth is simplest):
- [ ] `gcloud auth login` + `gcloud config set project <id>` (gcloud installed via dev.nix)
- [ ] `kubectl krew install oidc-login` (krew plugin you used)
- [ ] `npm install -g cubejs-cli` (your one global npm pkg)
- [ ] Claude plugins: re-add the marketplaces listed in `home/samuel/claude/installed-plugins.md`
      (claude-hud, datatactics-skills), then install. Log in to Claude Code.

## Phase 6 — Personal overrides & services
- [ ] **flt.conf SSH override** (your `u119230` + `%%` edit on the shared repo):
      `cd ~/.ssh/config.d-dtacs && git apply ~/flt.conf.personal-override.patch`
- [ ] **todo automation**: `systemctl --user enable --now refresh-todo.timer` (units restored from bundle);
      confirm `~/todo.md` refreshes. Autostart `.desktop` already restored.
- [ ] **GNOME tweaks**: `dconf load /org/gnome/ < ~/gnome-settings-backup.dconf`
- [ ] **Firefox**: either sign into Firefox Sync, OR the restored `logins.json`/`key4.db`/`places.sqlite`
      in `~/.mozilla/firefox/<profile>/` carry passwords+bookmarks (profile name will differ — copy into the new profile dir).

## Phase 7 — Verify & clean up
- [ ] `sops -d` a cluster secret to confirm the age key works.
- [ ] `kubectl get ns` against a cluster; `docker run hello-world`.
- [ ] zsh prompt (p10k), aliases, and `~/.zsh_history` all present.
- [ ] 🔑 **ROTATE the plaintext credentials** you carried: the git PAT/token in
      `~/Documents/git_password_save.txt` and the token file — then delete the plaintext copies and
      rely on the keyring/credential manager going forward.
- [ ] Once everything's confirmed, securely wipe the decrypted files you don't want lingering.

---
### Quick reference — what's where
| Need | Source |
|---|---|
| age key, ssh, kube, docker, keyring, shell history, Documents, firefox pw | 🔐 bundle |
| project notes, tutorials, full .claude tar | 💽 drive `work_backup_pre_nix_01062026/` |
| NixOS config, Claude config+memory+skills, VS Code config+ext list | 📦 this repo |
| git tokens / Trackspace PAT / Nextcloud / MinIO | keyring (bundle) + `Documents/git_password_save.txt` |
