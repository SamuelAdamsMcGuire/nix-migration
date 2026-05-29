# Host: samuel-21tb003mge  (Lenovo ThinkPad, AMD Ryzen AI 7 PRO 350 / Radeon 860M)
# Imports the shared fleet modules + this machine's hardware specifics.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix   # GENERATED on the target — see README before building
    ../../modules/common.nix
    ../../modules/desktop-gnome.nix
    ../../modules/networking.nix
    ../../modules/dev.nix
    ../../modules/users.nix
    ../../modules/secrets.nix
  ];

  networking.hostName = "samuel-21tb003mge";

  # ---- Boot (UEFI) ----
  boot.loader.systemd-boot.enable = true;        # simpler than GRUB for a fresh UEFI install
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- AMD CPU + GPU ----
  hardware.cpu.amd.updateMicrocode = true;       # was amd-ucode
  hardware.graphics.enable = true;               # amdgpu (Radeon 860M); was vulkan-radeon/mesa
  hardware.graphics.enable32Bit = true;          # 32-bit GL for the odd game/app

  # ThinkPad niceties
  services.fprintd.enable = true;                # fingerprint reader (was fprintd)
  services.power-profiles-daemon.enable = true;  # was power-profiles-daemon
  hardware.bluetooth.enable = true;

  # Audio — PipeWire (replaces manjaro-pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
