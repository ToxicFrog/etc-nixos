# General configuration shared between all of the systems that are primarily
# used by alex -- isis, pladix, and excavatorix.

{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./users.nix
  ];

  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.utf8";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ samsung-unified-linux-driver_1_00_37 ];

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  # Enable Munin system monitor
  services.munin-node = {
    enable = true;
    extraConfig = ''
      cidr_allow 192.168.1.0/24
    '';
  };

  nix.settings.auto-optimise-store = true;
  system.autoUpgrade = {
    enable = false;
  };
}
