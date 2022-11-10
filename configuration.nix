# Configuration specific to ancilla.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./users.nix
    ./packages.nix
    ./doomrl-server.nix
    ./services/default.nix
    ./overlays/default.nix
    ./secrets/netmount.nix
  ];

  system.stateVersion = "16.09";
  boot.cleanTmpDir = true;
  time.timeZone = lib.mkDefault "America/Toronto";
  programs.zsh.enable = true;

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

  nix = {
    useSandbox = true;
    gc.automatic = true;
    gc.options = "--delete-older-than 60d";
    autoOptimiseStore = true;
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
