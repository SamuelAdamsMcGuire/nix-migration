# GNOME desktop — replaces the ~90 gnome-*/manjaro-* pacman packages with options.
{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Printing + scanning (was system-config-printer / simple-scan on Manjaro)
  services.printing.enable = true;
  services.avahi = { enable = true; nssmdns4 = true; };   # network printer/host discovery
  hardware.sane.enable = true;

  # Trim GNOME default apps you don't use (mirror of your Manjaro choices).
  # Add/remove freely — this is just to avoid shipping games/tour/etc.
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour epiphany geary gnome-music
    iagno hitori atomix tali gnome-chess quadrapassel gnome-mines
  ];

  # GNOME Shell extensions — declared, not pacman-installed.
  # Enable the matching UUIDs via dconf (import your dumped gnome-settings — see README).
  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    arcmenu
    dash-to-dock
    dash-to-panel
    forge
    gsconnect
    space-bar
    desktop-icons-ng-ding   # gtk4-desktop-icons-ng equivalent
    # x11gestures, gnome-ui-tune, legacy-theme-auto-switcher:
    # verify exact attr names with: nix search nixpkgs gnomeExtensions
  ];

  # dconf is required for extension + tweak settings to persist.
  programs.dconf.enable = true;

  # Keyring (holds your Trackspace PAT / Nextcloud / MinIO secrets — see todo automation).
  services.gnome.gnome-keyring.enable = true;

  # Fonts (was noto-fonts*/ttf-hack/ttf-indic-otf on Manjaro)
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-emoji noto-fonts-extra
    hack-font
  ];
}
