# zsh — translated from your Manjaro ~/.zshrc into home-manager.
# Drop the backed-up ~/.p10k.zsh into this directory as `p10k.zsh` (see home.file below).
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;       # was the zsh-autosuggestions plugin
    syntaxHighlighting.enable = true;   # was the zsh-syntax-highlighting plugin

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;
      save = 10000;
      share = true;                     # SHARE_HISTORY
      append = true;                    # APPEND_HISTORY / INC_APPEND_HISTORY
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" ];
      # theme intentionally empty — powerlevel10k loaded as a plugin below
      theme = "";
    };

    # powerlevel10k prompt (replaces the oh-my-zsh custom theme install)
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    shellAliases = {
      cls = "clear";
      ".." = "cd ..";
      "..." = "cd ../..";
      ports = "netstat -tulanp";
      myip = "curl ifconfig.me";
      flightpos = "code ~/projects/flightpos";
      flt = "code ~/projects/flt";
      fraalliance = "code ~/projects/fraalliance";
      vigilo = "code ~/projects/vigilo";
      k = "kubectl";
      mc = "mcli";
      hmo = "$HOME/.claude/skills/horizon-ml-ops/scripts/horizon_models.py";
      # 'update' rewritten for NixOS (was: sudo pacman -Syu)
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#samuel-21tb003mge";
      # NOTE: the old `vpn` alias embedded a plaintext password. Re-add it
      # SECURELY once the secret is in sops/keyring, e.g.:
      #   vpn = "sudo -E gpclient connect --default-browser <gateway>";
      # and let gpclient prompt, or read the secret from sops at runtime.
    };

    # p10k instant-prompt + sourcing the carried-over config; plus history-search bindkeys.
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # p10k instant prompt — must stay near the top
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkOrder 1500 ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        bindkey "^[[A" history-search-backward
        bindkey "^[[B" history-search-forward
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
      '')
    ];
  };

  # Carry the powerlevel10k config verbatim from your backup.
  # Copy the restored ~/.p10k.zsh to home/samuel/p10k.zsh in this repo, then this links it.
  home.file.".p10k.zsh".source = ./p10k.zsh;
}
