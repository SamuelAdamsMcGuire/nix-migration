# Claude Code setup — declarative restore so you don't start from scratch.
#
# Two classes of state, handled differently:
#   - STATIC content you author and Claude only READS  -> symlinked from this repo
#     (edit it here, `nixos-rebuild`, done). Read-only store symlink is fine.
#   - MUTABLE state Claude WRITES at runtime (memory, local settings) -> seeded
#     once via an activation copy so it stays writable and isn't clobbered later.
#
# NOT managed here (reinstall / re-login on the new machine):
#   - plugins/  -> reinstall the marketplaces listed in claude/installed-plugins.md
#   - auth      -> just log in once
#   - transcripts / caches -> disposable (full tar on the backup drive if ever needed)
{ config, pkgs, lib, ... }:

let
  memoryDir = ".claude/projects/-home-samuel/memory";
in
{
  # ---- STATIC: symlinked, edit-in-repo ----
  home.file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
  home.file.".claude/skills".source = ./claude/skills;   # graphify, horizon-ml-ops, ...

  # ---- MUTABLE: seed once, keep writable ----
  # settings.json / settings.local.json: Claude (and the permission system) write
  # these, so we copy rather than symlink, and only if absent (don't stomp live state).
  home.activation.seedClaudeSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for f in settings.json settings.local.json; do
        dst="$HOME/.claude/$f"
        if [ ! -e "$dst" ]; then
          $DRY_RUN_CMD mkdir -p "$HOME/.claude"
          $DRY_RUN_CMD cp ${./claude}/$f "$dst"
          $DRY_RUN_CMD chmod u+w "$dst"
        fi
      done
    '';

  # memory/: precious and append-only. Seed from the repo only if not already present,
  # so a fresh machine gets your accumulated memory but an existing one is never clobbered.
  home.activation.seedClaudeMemory =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mem="$HOME/${memoryDir}"
      if [ ! -e "$mem/MEMORY.md" ]; then
        $DRY_RUN_CMD mkdir -p "$mem"
        $DRY_RUN_CMD cp -rn ${./claude/memory}/. "$mem"/
        $DRY_RUN_CMD chmod -R u+w "$mem"
      fi
    '';

  # Claude Code itself: install via npm on the new machine, or add a package here once
  # you've decided how (nixpkgs may lag the latest CLI; npm -g is often simplest).
  # home.packages = [ pkgs.claude-code ];  # uncomment if you want the nixpkgs build
}
