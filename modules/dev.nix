# Developer tooling — system-level infra/CLI tools + container runtime.
# Language runtimes (python/node/go/...) for PROJECTS belong in per-repo devShells,
# not here. A thin baseline lives in home/samuel/packages.nix for convenience.
{ config, pkgs, lib, ... }:

{
  # Docker (you're in the docker group — see modules/users.nix)
  virtualisation.docker.enable = true;

  # gnome-boxes / libvirt VMs (was gnome-boxes on Manjaro)
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    # Kubernetes / GitOps stack
    kubectl
    kubectl-krew          # `kubectl krew` — re-add the oidc-login plugin after first boot
    kustomize
    sops
    age                   # was MISSING on Manjaro; now first-class for your sops workflow
    kubernetes-helm       # add if you need it; harmless to keep

    # Cloud / data
    google-cloud-sdk      # was AUR google-cloud-cli
    minio-client          # provides `mcli`
    postgresql            # client + server tools
    dbeaver-bin           # DB GUI
    mdbtools              # was the lone Homebrew package
    pandoc

    # Misc dev utilities
    gnumake
    gcc
  ];
}
