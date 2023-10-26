# Configuration specific to ancilla.

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ./packages.nix
    ../secrets/netmount.nix
    ./services/default.nix
    ./virtualization.nix
  ];

  system.stateVersion = "16.09";

  # Use a somewhat larger font on the tty.
  console.font = "sun12x22";

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

  nix.settings.max-jobs = lib.mkDefault 4;

  security.acme = {
    defaults.email = "webmaster@ancilla.ca";
    acceptTerms = true;
  };

  # TODO a lot of this should be moved to packages.nix
  environment.systemPackages = with pkgs; [
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
    qbittorrent-nox
    weechat
    # keybase keybase-gui # keybase chat
    # notmuch alot gmailieer # mail reading
    doomrl
    timg tiv
    clojure leiningen
  ];

  sound.enable = true;
  users.users = (import ../secrets/users.nix { config = config; pkgs = pkgs; });
}
