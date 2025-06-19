# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, secrets, unstable, ... }:

let
  users = secrets.users { inherit config pkgs; };
in {
  imports =
    [
      ./hardware-configuration.nix
      # ../ancilla/services/syncthing.nix
      # ./camera.nix
      ./sound.nix
    ];

  networking = {
    hostName = "pladix";
    domain = "ancilla.ca";
    networkmanager.enable = false;
  };

  users.users = let
    pladix-users = secrets.pladix { inherit pkgs; };
  in {
    root = users.root // pladix-users.root;
    alex = users.alex;
    bex = users.bex;
    pladix = pladix-users.pladix;
  };

  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1-2 --mode 1920x1080
  '';
  services.displayManager.defaultSession = "plasmawayland";

  services.displayManager.autoLogin = {
    enable = true;
    user = "alex";
  };

  # nvidia has some serious issues here.
  # If we disable it, we run entirely with the onboard video card, which is
  # Fine I Guess but not suitable for a lot of 3d gaming.
  # If we enable it in sync (always on) mode, it works fine for 3d gaming, but
  # SDDM user switching breaks and even logging out and back in is not guaranteed
  # to work.
  # If we enable it in offload mode, everything works fine, but offloaded programs
  # have <50% the performance that we get in sync mode.
  # At the moment we reluctantly put it in sync mode and just accept that user
  # switching will never work.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    # powerManagement.enable = true;
    # powerManagement.finegrained = true;
    nvidiaSettings = true;
    prime = {
      sync.enable = true;
      # offload.enable = true;
      # offload.enableOffloadCmd = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # Enabling offload universally causes it to log in to a black screen.
  # environment.sessionVariables = {
  #   __NV_PRIME_RENDER_OFFLOAD = "1";
  #   __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
  #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #   __VK_LAYER_NV_optimus = "NVIDIA_only";
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  services.apcupsd = {
    enable = true;
    configText = ''
      UPSNAME apc700
      UPSTYPE usb
      NISIP 127.0.0.1
      BATTERYLEVEL 80
      MINUTES 30
      KILLDELAY 0
      NOLOGON disable
    '';
  };

  programs.adb.enable = true;
  environment.systemPackages = with pkgs; [
    chromium  # ffmpeg/libavcodec is part of the common package set
    unstable.gdlauncher-carbon
    golly
    goxel
    koboredux-free
    scrcpy  # for android stuff
    vscodium
  ];
}
