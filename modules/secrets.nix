# sops-nix — matches your existing sops + age workflow (ops-k8s/vigilo/fraalliance).
# The age key from your migration backup (~/.config/sops/age/keys.txt) is the
# decryption key. Restore it BEFORE the first `nixos-rebuild` that needs a secret.
{ config, pkgs, lib, ... }:

{
  sops = {
    # Default file that holds encrypted secrets (see .sops.yaml for recipients).
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # Decrypt using your personal age key (restored from the backup bundle).
    age.keyFile = "/home/samuel/.config/sops/age/keys.txt";

    # ---- Declare individual secrets here as you add them, e.g.: ----
    # secrets."vpn/password" = {
    #   owner = "samuel";
    #   # then reference at runtime via config.sops.secrets."vpn/password".path
    # };
  };

  # sops itself + age available system-wide.
  environment.systemPackages = with pkgs; [ sops age ];
}
