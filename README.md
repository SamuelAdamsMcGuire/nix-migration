# Datatactics laptop fleet — NixOS config

Flake-based, modular NixOS + home-manager configuration for company laptops.
Migrated from Manjaro (see `~/nixos-migration-inventory.md` for the source inventory).

## Layout
```
flake.nix                     inputs (nixpkgs 25.11, home-manager, sops-nix) + host outputs
.sops.yaml                    age recipients for secret encryption
modules/                      SHARED base — every laptop imports these
  common.nix                  nix/flakes, locale, base CLI, zsh enable
  desktop-gnome.nix           GNOME, printing, fonts, shell extensions
  networking.nix              NetworkManager + VPN plugins + GlobalProtect
  dev.nix                     docker, libvirt, k8s/cloud CLI tools
  users.nix                   user `samuel` + groups
  secrets.nix                 sops-nix wiring (age key from backup)
hosts/
  samuel-21tb003mge/          this ThinkPad (AMD)
    default.nix               imports modules + machine specifics
    hardware-configuration.nix  ⚠️ PLACEHOLDER — regenerate on target
home/samuel/                  home-manager user config
  default.nix                 entry + direnv (per-project devShells)
  packages.nix                GUI apps + dev-runtime baseline
  zsh.nix                     full .zshrc translation (aliases, p10k, history)
  git.nix                     git identity + prefs
  p10k.zsh                    ⚠️ ADD — copy your restored ~/.p10k.zsh here
secrets/                      sops-encrypted secrets.yaml (create when needed)
```

## First install on a target machine
1. Boot the NixOS installer, partition + mount to `/mnt` (UEFI; ESP at `/mnt/boot`).
2. `sudo nixos-generate-config --root /mnt` and copy the generated
   `/mnt/etc/nixos/hardware-configuration.nix` over the placeholder in
   `hosts/samuel-21tb003mge/hardware-configuration.nix`.
3. Clone this repo, then:
   `sudo nixos-install --flake .#samuel-21tb003mge`
4. Reboot.

## Restore from the migration backup bundle
Decrypt `nixos-migration-backup.tar.zst.gpg` and place:
- `~/.config/sops/age/keys.txt`  → required before any sops secret builds
- `~/.ssh/` (key `yes` + reapply `flt.conf.personal-override.patch`)
- `~/.kube/config`, `~/.docker/config.json`
- `~/.local/share/keyrings/` (todo secrets) — needs gnome-keyring + same login pw
- the todo automation (`.local/bin/*`, systemd user units, autostart, `todo.md`)
- `~/.zsh_history`, and copy `~/.p10k.zsh` → `home/samuel/p10k.zsh` in this repo
- `flight-positioning.bundle` → `git clone` it back

Then `git apply ~/flt.conf.personal-override.patch` inside the cloned config.d-dtacs,
and re-add the krew plugin: `kubectl krew install oidc-login`.

## Day-to-day
- Apply changes:  `sudo nixos-rebuild switch --flake ~/nixos-config#samuel-21tb003mge`
  (aliased to `update`)
- Update inputs:  `nix flake update` then rebuild
- Roll back:      pick a previous generation at boot, or `nixos-rebuild switch --rollback`

## Adding another fleet laptop
Copy `hosts/samuel-21tb003mge/` to `hosts/<new>/`, regenerate its
`hardware-configuration.nix`, add a `nixosConfigurations.<new>` entry in `flake.nix`,
and (for a different user) parameterise `modules/users.nix` + add a `home/<user>/`.

## Known follow-ups (from the inventory)
- ⚠️ Move the GlobalProtect VPN password out of a shell alias into sops/keyring; rotate it.
- Import GNOME tweaks: `dconf load /org/gnome/ < ~/gnome-settings-backup.dconf`
  (run `dconf dump /org/gnome/ > …` on Manjaro BEFORE wiping).
- Verify uncertain gnomeExtensions attr names: `nix search nixpkgs gnomeExtensions`.
- Consider bumping nixpkgs 25.11 → 26.05 after the first machine is validated.
- Per-project `devShells`: add a `flake.nix` to each repo (flt/horizon/fraalliance/...).
```
