# Configuration specific to ancilla.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ./overlays/default.nix
    ./packages.nix
    ./secrets/netmount.nix
    ./services/default.nix
    ./users.nix
    ./virtualization.nix
  ];

  system.stateVersion = "16.09";
  boot.tmp.cleanOnBoot = true;
  time.timeZone = lib.mkDefault "America/Toronto";
  programs.zsh.enable = true;

  # Compatibility shim for running non-nixos binaries
  programs.nix-ld.enable = true;
  environment.variables = {
#      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
#        pkgs.stdenv.cc.cc
#        pkgs.openssl
#      ];
      #NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };

  i18n = {
    defaultLocale = "en_CA.UTF-8";
    extraLocaleSettings.LC_TIME = "en_DK.UTF-8";
  };

  # Use a somewhat larger font on the tty.
  console.font = "sun12x22";

  # Enable whatis/apropos.
  documentation.man.generateCaches = true;

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];

  networking.hostName = "ancilla";
  networking.domain = "ancilla.ca";
  networking.hostId = "c4262b22";

  networking.firewall = {
    allowPing = true;
    allowedTCPPortRanges = [
      { from = 8000; to = 8100; }
      { from = 24000; to = 25000; }
    ];
    allowedTCPPorts = [
      22          # sshd
      80 443      # httpd
      8900        # weechat
      22000       # syncthing transfers
    ];
    allowedUDPPorts = [
      21027 # syncthing discovery
    ];
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 60d";
  };
  nix.settings = {
    sandbox = true;
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 4;
  };

  security.acme = {
    defaults.email = "webmaster@ancilla.ca";
    acceptTerms = true;
  };

  # TODO a lot of this should be moved to packages.nix
  environment.systemPackages = with pkgs; [
    beets
    digikam # for digitaglinktree
    dnsutils
    dosage
    elinks
    # ipfs
    jq
    rsync
    jshon
    xxd pv exiftool sigal imagemagick # for share
    lgogdownloader
    tmuxinator
    lm_sensors
    nodejs  # for discord-ircd
    qbittorrent-nox
    #(python27.withPackages (ps: [ps.mutagen ps.websocket_client])) # for morg and weeslack
    recoll  # log searching
    sshfs
    weechat
    youtube-dl # for downloading podcasts
    keybase keybase-gui # keybase chat
    notmuch alot gmailieer # mail reading
    doomrl
    timg tiv
    clojure leiningen
    jdk
    #jdk #jdk14_headless
  ];
}
