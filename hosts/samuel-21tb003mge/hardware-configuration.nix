# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLACEHOLDER — REPLACE ON THE TARGET MACHINE                              │
# │                                                                           │
# │  This file MUST be regenerated on the actual NixOS machine, because it    │
# │  encodes real disk UUIDs / partition layout that only exist after you     │
# │  partition + install. From the NixOS installer (or after first boot):     │
# │                                                                           │
# │      sudo nixos-generate-config --root /mnt        # during install       │
# │      # then copy the generated /mnt/etc/nixos/hardware-configuration.nix  │
# │      # over THIS file.                                                     │
# │                                                                           │
# │  The committed stub below is intentionally minimal so the flake parses,   │
# │  but it will NOT boot until replaced with the generated version.          │
# └─────────────────────────────────────────────────────────────────────────┘
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- These come from `nixos-generate-config` on the real disk: ---
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/REPLACE-ME";
  #   fsType = "ext4";              # or btrfs if you reformat
  # };
  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-uuid/REPLACE-ME";
  #   fsType = "vfat";
  # };
  # swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
