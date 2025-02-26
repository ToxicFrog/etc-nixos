{ pkgs, unstable, oldstable, ... }:

{
  #environment.extraOutputsToInstall = [ "doc" "devdoc" "man" ];
  environment.systemPackages = with pkgs; [
    abcde mkcue cdparanoia
    oldstable.alot # broken in 24.11 due to python gpg breakage: https://github.com/NixOS/nixpkgs/issues/354166
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
    pcal
    recode
    wring
    unstable.yt-dlp
  ];
}
