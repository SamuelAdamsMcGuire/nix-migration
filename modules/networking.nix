# Networking — NetworkManager + the VPN plugins you had on Manjaro.
{ config, pkgs, lib, ... }:

{
  networking.networkmanager = {
    enable = true;
    # Mirrors your Manjaro networkmanager-* plugin set.
    plugins = with pkgs; [
      networkmanager-openconnect
      networkmanager-openvpn
      networkmanager-pptp
      networkmanager-strongswan
      networkmanager-vpnc
      networkmanager-sstp
    ];
  };

  # GlobalProtect VPN (was AUR globalprotect-openconnect-git).
  # Provides `gpclient`. NOTE: do NOT recreate the hardcoded-password `vpn` alias
  # from your old .zshrc — see home/samuel/zsh.nix for the secure approach.
  services.globalprotect.enable = true;
  environment.systemPackages = [ pkgs.globalprotect-openconnect ];

  networking.firewall.enable = true;
}
