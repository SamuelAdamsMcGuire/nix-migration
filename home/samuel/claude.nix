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
  # CLAUDE.md is hand-authored global instructions you only ever edit in the repo.
  home.file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;

  # ---- MUTABLE: seed once, keep writable ----
  # Everything Claude WRITES at runtime is copied (not symlinked) and only if absent,
  # so the tool can keep writing and a re-run never clobbers live state:
  #   - skills/  : skill-creator writes new skills here
  #   - settings : Claude + the permission system write these
  # The repo is the SOURCE/restore point — commit changes back when you evolve them.
  home.activation.seedClaudeSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.claude"
      for f in settings.json settings.local.json; do
        dst="$HOME/.claude/$f"
        if [ ! -e "$dst" ]; then
          $DRY_RUN_CMD cp ${./claude}/$f "$dst"
          $DRY_RUN_CMD chmod u+w "$dst"
        fi
      done
      if [ ! -e "$HOME/.claude/skills" ]; then
        $DRY_RUN_CMD cp -rn ${./claude/skills} "$HOME/.claude/skills"
        $DRY_RUN_CMD chmod -R u+w "$HOME/.claude/skills"
      fi
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
