# User accounts. Per-fleet you'd parameterise this; for now it's your single user.
{ config, pkgs, lib, ... }:

{
  users.users.samuel = {
    isNormalUser = true;
    description = "Samuel McGuire";
    shell = pkgs.zsh;
    # Mirrors your Manjaro groups (minus Manjaro-only ones).
    extraGroups = [
      "wheel"          # sudo
      "networkmanager"
      "docker"
      "libvirtd"
      "audio"
      "video"
      "input"
      "storage"
      "lp"             # printing
    ];
  };
}
