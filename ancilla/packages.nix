{ pkgs, unstable, ... }:

{
  # Needed by python mautrix bridges...for now
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

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
    leiningen
    lieer
    notmuch
    nox
    ledger-autosync
    recode
    wring
    unstable.yt-dlp
  ];
}
