# Configuration specific to ancilla.

{ config, pkgs, lib, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./users.nix
    ./packages.nix
    ./doomrl-server.nix
    ./services.nix
    ./overlays/default.nix
    ./secrets/netmount.nix
  ];

  system.nixos.stateVersion = "16.09";
  boot.cleanTmpDir = true;
  time.timeZone = lib.mkDefault "America/Toronto";
  programs.zsh.enable = true;

  # Use a somewhat larger font on the tty.
  i18n.consoleFont = "sun12x22";

  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];

  networking.hostName = "ancilla.ancilla.ca";
  networking.hostId = "c4262b22";
  networking.extraHosts = ''
   192.168.86.101 thoth
   192.168.86.147 lector
   192.168.86.148 maple
  '';

  networking.firewall = {
    allowPing = true;
    allowedTCPPorts = [
      22          # sshd
      80 443      # httpd
      3666 3667   # doomrl telnet and websocket
      25 465 587  # smtp
      143 993     # imap
      8900        # weechat
      5634        # kodi media library
      22000       # syncthing transfers
    ];
    allowedUDPPorts = [
      21027 # syncthing discovery
    ];
  };

  nix = {
    useSandbox = true;
    gc.automatic = true;
    gc.options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    alpine
    beets
    calibre
    digikam # for digitaglinktree
    elinks
    ipfs
    jshon
    ffmpeg-full
    nodejs  # for discord-ircd
    (python27.withPackages (ps: [ps.mutagen ps.websocket_client])) # for mo and weeslack
    rtorrent
    sshfs
    skicka  # for backup upload to grive
    timg
    weechat
    gpodder unstable.youtube-dl sqlite  # for downloading podcasts
  ];

  zramSwap = {
    enable = true;
    numDevices = 1;
  };
}
