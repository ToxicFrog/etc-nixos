# deploy with:
# NIXOS_CONFIG=systems/pladix/configuration.nix nixos-rebuild --target-host=pladix switch

{ config, pkgs, modulesPath, ... }:

let
  unstable = import <nixos-unstable> { config.allowUnfree = true; };
in {
  system.stateVersion = "20.09"; # Did you read the comment?

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../secrets/pladix.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.postBootCommands = ''
    # Disable wake-on-mouse
    echo disabled > /sys/bus/usb/devices/5-2.1/power/wakeupecho disabled > /sys/bus/usb/devices/5-2.1/power/wakeup
  '';

  networking = {
    hostName = "pladix";
    domain = "ancilla.ca";
    networkmanager.enable = true;
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  #networking.interfaces.enp0s25.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  console.font = "latarcyrheb-sun32";
  console.keyMap = "us";

  # Set your time zone.
  time.timeZone = "America/Toronto";

  programs.zsh.enable = true;

  services.printing = {
    enable = true;
    drivers = with pkgs; [ samsung-unified-linux-driver_1_00_37 ];
  };

  #programs.steam.enable = true;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages =
  with pkgs; let
    steam = (unstable.steam.override { extraPkgs = pkgs: with pkgs; [ pango harfbuzz libthai ]; });
  in [
    # system tools
    zip unzip ncdu htop xscreensaver wget ark git
    # for gaming
    jre retroarchBare stepmania lutris scummvm wine
    #(unstable.steam.override { extraPkgs = pkgs: with pkgs; [ pango harfbuzz libthai ]; })
    steam steam.run
    fluidsynth soundfont-fluid
    #steam-run # for gog games, etc
    caffeine-ng # power control for retroarch
    antimicroX # controller support for keyboard-only games
    # for dbgl
    swt dosbox gsettings-desktop-schemas
    # for exodos-ll
    unstable.dosbox-staging dialog
    # misc games
    gnome.quadrapassel ltris lbreakout2
    # for media playback
    chromium ffmpeg-full
    vulkan-tools vulkan-loader
    vlc
    #libsForQt5.phonon-backend-vlc
    #libsForQt5.phonon-backend-gstreamer gst-plugins-good gst-plugins-ugly
  ];
  nixpkgs.config.permittedInsecurePackages = [
    "ffmpeg-2.8.17"
  ];

  # List services that you want to enable:
  services.munin-node = {
    enable = true;
    extraConfig = ''
      cidr_allow 192.168.86.0/24
    '';
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  # Fix for HDMI audio going away after suspend
  powerManagement.resumeCommands = ''
    sleep 2
    ${pkgs.sudo}/bin/sudo -u pladix pacmd set-card-profile 0 output:hdmi-stereo
  '';

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable hardware accelerated rendering.
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [vaapiVdpau vaapiIntel];
    extraPackages32 = with pkgs; [vaapiVdpau vaapiIntel];
  };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoLogin.relogin = true;
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "pladix";
  };
  services.xserver.desktopManager.plasma5.enable = true;
  systemd.services.display-manager.wants = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];
  systemd.services.display-manager.after = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];

  system.autoUpgrade = {
    enable = false;
  };

  # Stuff from hardware-configuration.nix. FIXME: regenerate for pladix.
  boot.initrd.availableKernelModules = [ "ahci" "ohci_pci" "ehci_pci" "xhci_pci" "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/pladix-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/PLADIXBOOT";
      fsType = "vfat";
    };

#  fileSystems."/data" =
#    { device = "/dev/disk/by-uuid/5b839175-8a46-4b03-8f01-08fd74333514";
#      fsType = "ext4";
#    };

#  fileSystems."/nix/store" =
#    { device = "/data/nix";
#      options = [ "bind" ];
#    };

  fileSystems."/ancilla" =
    { device = "ancilla:/ancilla";
      fsType = "nfs";
    };

  swapDevices = [
    { device = "/dev/disk/by-label/pladix-swap"; }
  ];

#  nixpkgs.overlays = [
#    (self: super: {
#      steam = super.steam.override {
#        extraPkgs = pkgs: with pkgs; [ pango harfbuzz libthai ];
#      };
#    })
#  ];
}
