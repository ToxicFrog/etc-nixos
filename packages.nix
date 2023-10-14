{ pkgs, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  nixpkgs.config.allowUnfree = true;
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    atop
    atuin
    beets-unstable
    binutils  # for strings and nm
    calibre  # for calibre-server
    unstable.chezmoi
    dos2unix
    dtrx
    ffmpeg-vgz
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
    (recoll.override { withGui = false; })  # log searching
    rlwrap
    sshfs sshfs-fuse
    stdmanpages
    taskwarrior
    tmux
    unrar
    unzip
    wget
    wring
    unstable.yt-dlp
    zip
    # dlique and hangbrain
    # geckodriver is in ~/opt because it needs a special build
    chromium chromedriver firefox
  ];
}
