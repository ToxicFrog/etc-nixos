{ pkgs, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  nixpkgs.config.allowUnfree = true;
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    atop
    binutils  # for strings and nm
    dos2unix
    dtrx
    file
    findutils
    gcc
    gdb
    gitAndTools.gitFull
    git-crypt git-secrets
    gnumake
    # google-chrome
    hledger hledger-ui hledger-web
    htop
    jre
    kpcli
    ledger
    leiningen
    luajit
    man-pages
    ncdu
    nox
    p7zip
    posix_man_pages
    python
    ledger-autosync
    python3
    sshfsFuse
    stdmanpages
    taskwarrior
    tmux
    unrar
    unzip
    wget
    zip
  ];
}
