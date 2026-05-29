# User-level apps + a thin dev-runtime baseline.
# GUI apps and personal CLI tools live here (home.packages), so they're scoped
# to your user rather than system-wide.
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # ---- Browsers / comms ----
    firefox
    google-chrome          # unfree (allowed in common.nix)
    thunderbird

    # ---- Editors / IDE ----
    vscode                 # unfree; was AUR visual-studio-code-bin
    meld

    # ---- Docs / office / media ----
    typora                 # unfree
    libreoffice-still
    evince
    gthumb
    lollypop
    ffmpeg

    # ---- Dev clients / API ----
    postman                # unfree; was AUR postman-bin

    # ---- Personal CLI ----
    # (broad CLI baseline is in modules/common.nix; add user-only extras here)

    # ---- Language runtimes: convenience baseline ONLY ----
    # Real per-project versions come from each repo's devShell + direnv.
    uv                     # your primary Python manager
    nodejs_22
    nodePackages.pnpm
    go
    rustup
    jdk21
    ruby
  ];
}
