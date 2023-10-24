# Configuration specific to ancilla.

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ./overlays.nix
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
  # see https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
  nix.registry = {
  	nixpkgs.flake = inputs.nixpkgs;
  	unstable.flake = inputs.nixpkgs-unstable;
  	local.flake = inputs.nixpkgs-local;
  };
  nix.nixPath = [
  	"nixpkgs=/etc/channels/nixpkgs"
  	"unstable=/etc/channels/nixpkgs-unstable"
  	"local=/etc/channels/nixpkgs-local"
  	"nixos-config=/etc/nixos/configuration.nix"
  	"/nix/var/nix/profiles/per-user/root/channels"
    # nixpkgs-overlays = /etc/nixos/overlays # TODO
  ];
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
  environment.etc."channels/nixpkgs-unstable".source = inputs.nixpkgs-unstable.outPath;
  environment.etc."channels/nixpkgs-local".source = inputs.nixpkgs-local.outPath;

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
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

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
}
