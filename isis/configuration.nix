# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, secrets, ... }:

let
  users = secrets.users { inherit config pkgs; };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "isis"; # Define your hostname.
  networking.domain = "ancilla.ca";
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.useDHCP = false;
  #networking.interfaces.wlp2s0.useDHCP = true;
  networking.networkmanager.enable = true;

  console.font = "sun12x22";
  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
  programs.zsh.enable = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget nano htop chromium
    unstable.steam unstable.steam.run ffmpeg-full vivaldi-ffmpeg-codecs unstable.scummvm opentyrian
    swt dosbox gsettings-desktop-schemas gargoyle jre8 gsettings-desktop-schemas xorg.libXtst
    libnotify
  ];
  programs.steam.enable = true;
  programs.steam.package = unstable.steam;
  # nixpkgs.config.packageOverrides = pkgs: {
  #   steam = pkgs.steam.override {
  #     extraPkgs = pkgs: with pkgs; [
  #       libpng  # for dead cells
  #     ];
  #   };
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };
  services.gnome3.gnome-keyring.enable = true;
  # List services that you want to enable:
  services.munin-node = {
    enable = true;
    extraConfig = ''
      cidr_allow 192.168.86.0/24
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    forwardX11 = true;
    allowSFTP = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 4949 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    autoLogin = {
      enable = true;
      relogin = true;
      user = "alex";
    };
  };
  #services.xserver.desktopManager.plasma5.enable = true;
  #services.xserver.desktopManager.mate.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  #services.xserver.desktopManager.lxqt.enable = true;
  #services.xserver.desktopManager.lumina.enable = true;

  users.users.root = users.root;
  users.users.alex = users.alex;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
  nixpkgs.config.allowUnfree = true;
}

