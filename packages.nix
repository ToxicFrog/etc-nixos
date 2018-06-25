{ pkgs, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  nixpkgs.config.allowUnfree = true;
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    atop
    binutils  # for strings and nm
    bup
    dos2unix
    dtrx
    file
    findutils
    gcc
    gdb
    gitAndTools.gitFull
    gnumake
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
    stdmanpages
    taskwarrior
    tmux
    unrar
    unzip
    wget
    zip
  ];
}
