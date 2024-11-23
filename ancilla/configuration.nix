# Configuration specific to ancilla.

{ config, pkgs, lib, inputs, secrets, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ./packages.nix
    ./services/default.nix
    ./virtualization.nix
    secrets.ancilla.netmounts
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

  # Shared directories on /ancilla that should be writeable by anyone even if
  # someone else created subdirectories.
  users.groups.parents = {};
  system.activationScripts.shared-directory-acls = with pkgs; ''
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/documents
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/projects
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/scans
    ${acl}/bin/setfacl --recursive -m 'd:g:users:rwX,d:o::rX,g:users:rwX,o::rX' /ancilla/installs/games/Retroarch/games
  '';

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
    xxd pv exiftool imagemagick sigal # for share
    lgogdownloader
    ncmpcpp
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
  users.users = secrets.users { inherit config pkgs; };
}
