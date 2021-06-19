{ config, pkgs, ... }:

{
  imports = [
    ./secrets/pladix.nix
  ];

  system.stateVersion = "20.09"; # Did you read the comment?

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "pladix";
    domain = "ancilla.ca";
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.interfaces.enp2s0.useDHCP = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # system tools
    zip ncdu htop
    # for gaming
    # FIXME: find a solution for dbgl
    steam dosbox jre retroarchBare stepmania
    # for media playback
    chromium ffmpeg-full libsForQt5.vlc
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  system.autoUpgrade = {
    enable = false;
  };

  # Stuff from hardware-configuration.nix. FIXME: regenerate for pladix.
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "uas" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/2a68366d-7dde-4f7d-b5c7-1e5c5032b1fc";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4DB1-1D4D";
      fsType = "vfat";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/5b839175-8a46-4b03-8f01-08fd74333514";
      fsType = "ext4";
    };

  # swapDevices =
  #   [ { device = "/dev/disk/by-uuid/cef58c1d-8481-4510-b73b-ef669c3149e4"; }
  #   ];
}
