# Shared base — imported by every laptop in the fleet.
# Anything here applies to ALL machines; per-machine stuff lives in hosts/<name>/.
{ config, pkgs, lib, ... }:

{
  # ---- Nix / flakes ----
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # vscode / chrome / postman etc. are unfree
  nixpkgs.config.allowUnfree = true;

  # ---- Locale / time / keyboard ----
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";          # German physical keyboard
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # ---- Base CLI tooling present on every machine ----
  # Project/language deps do NOT go here — those live in per-repo devShells.
  environment.systemPackages = with pkgs; [
    git vim wget curl htop tree ripgrep jq yq-go rsync file
    unzip zip p7zip unrar pciutils usbutils
  ];

  # zsh must be enabled at system level to be a valid login shell.
  programs.zsh.enable = true;

  # Keep firmware updatable (replaces gnome-firmware/fwupd on Manjaro).
  services.fwupd.enable = true;

  # This should match the release you FIRST installed with. Do not bump casually.
  system.stateVersion = "25.11";
}
