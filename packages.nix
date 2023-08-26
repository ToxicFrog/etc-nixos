{ pkgs, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  nixpkgs.config.allowUnfree = true;
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    atop
    atuin
    binutils  # for strings and nm
    calibre  # for calibre-server
    unstable.chezmoi
    dos2unix
    dtrx
    ffmpeg-full
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
    #ledger
    leiningen
    lsd
    luajit
    man-pages
    nb micro
    ncdu
    nox
    p7zip
    posix_man_pages
    ledger-autosync
    python3
    recode
    rlwrap
    sshfs-fuse
    stdmanpages
    taskwarrior
    tmux
    unrar
    unzip
    wget
    wring
    zip
    # dlique and hangbrain
    # geckodriver is in ~/opt because it needs a special build
    chromium chromedriver firefox
  ];
}
