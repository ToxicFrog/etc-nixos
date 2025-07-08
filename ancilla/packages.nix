{ pkgs, unstable, ... }:

{
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    abcde mkcue cdparanoia
    alot
    atop
    # TODO: beancount
    beets-unstable
    calibre  # for calibre-server
    # chromium chromedriver  # no longer needed for dlique
    ffmpeg-vgz
    # geckodriver  # needs a special built, which is in ~/opt
    gcc
    gdb
    grip-search
    hledger hledger-ui hledger-web
    kpcli
    ledger-autosync
    leiningen
    lieer
    notmuch
    nox
    mp3gain
    pcal
    recode
    wring
    unstable.yt-dlp
  ];
}
