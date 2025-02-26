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
  # FIXME: this runs before zpool import does, so it doesn't work at boot time
  users.groups.parents = {};
  system.activationScripts.shared-directory-acls = with pkgs; ''
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/documents
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/projects
    ${acl}/bin/setfacl --recursive -m 'd:g:parents:rwX,g:parents:rwX' /ancilla/scans
    ${acl}/bin/setfacl --recursive -m 'd:g:users:rwX,d:o::rX,g:users:rwX,o::rX' /ancilla/installs/games/Retroarch/games
  '';

  # TODO a lot of this should be moved to packages.nix
  environment.systemPackages = with pkgs; [
    clojure leiningen
    digikam # for digitaglinktree
    dnsutils
    doomrl
    dosage
    elinks
    # ipfs
    ghostscript
    jq
    rsync
    jshon
    xxd pv exiftool imagemagick sigal # for share
    lgogdownloader
    ncmpcpp
    tmuxinator
    lm_sensors
    pcal
    qbittorrent-nox
    timg tiv
    weechat
    # keybase keybase-gui # keybase chat
  ];

  users.users = secrets.users { inherit config pkgs; };
}
