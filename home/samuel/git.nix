# git — your identity + the preferences you actually use.
{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Samuel McGuire";
    userEmail = "s.mcguire@datatactics.de";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;   # so `git push` on a new branch just works
      pull.rebase = false;
    };
  };
}
