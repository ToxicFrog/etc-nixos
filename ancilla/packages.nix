{ pkgs, unstable, ... }:

{
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    alot
    atop
    # TODO: beancount
    beets-unstable
    calibre  # for calibre-server
    # chromium chromedriver  # no longer needed for dlique
    ffmpeg-vgz
    firefox  # for dlique
    # geckodriver  # needs a special built, which is in ~/opt
    gcc
    gdb
    hledger hledger-ui hledger-web
    kpcli
    leiningen
    lieer
    notmuch
    nox
    ledger-autosync
    recode
    (recoll.override { withGui = false; })  # log searching
    wring
    unstable.yt-dlp
  ];
}
