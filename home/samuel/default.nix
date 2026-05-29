# home-manager — user-level config for samuel. Imported by the flake as a NixOS module.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./packages.nix
    ./zsh.nix
    ./git.nix
  ];

  home.username = "samuel";
  home.homeDirectory = "/home/samuel";
  home.stateVersion = "25.11";

  # direnv + nix-direnv — the mechanism that auto-loads per-project devShells.
  # This is the NixOS-idiomatic replacement for global language version managers.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
