# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../alex-common/default.nix
      ../../services/syncthing.nix
      ./camera.nix
    ];

  networking = {
    hostName = "pladix";
    domain = "ancilla.ca";
    networkmanager.enable = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  #services.xserver.displayManager.sddm.autoLogin.relogin = true;
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "pladix";
  };
  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = false;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable openGL.
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    #extraPackages = with pkgs; [vaapiVdpau vaapiIntel];
    #extraPackages32 = with pkgs; [vaapiVdpau vaapiIntel];
  };

  environment.systemPackages = with pkgs; [
    (retroarch.override {
      cores = with libretro; [
        dolphin mgba beetle-psx beetle-psx-hw bsnes snes9x gambatte pcsx2 nxengine ppsspp mupen64plus
      ];
    })
  ];

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
    '';
  };

  services.mpd = {
    enable = true;
    network.listenAddress = "any";
    user = "pladix"; group = "pladix";
    extraConfig = ''
      default_permissions "read,add,control,admin"
      zeroconf_enabled "yes"
      zeroconf_name "MPD @ %h"
      audio_output {
        type "pipewire"
        name "local pipewire output"
      }
      input {
        plugin "curl"
      }
    '';
  };
  systemd.services.mpd.environment = {
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    XDG_RUNTIME_DIR = "/run/user/1000"; # pladix
  };
}
