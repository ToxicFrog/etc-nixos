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
  i18n.supportedLocales = [ "all" ];

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ samsung-unified-linux-driver_1_00_37 ];

  fonts = {
    fontDir.enable = true;
    enableDefaultFonts = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    fonts = with pkgs; [
      corefonts
      google-fonts
      gentium
      inconsolata-lgc
      noto-fonts-cjk-sans
      noto-fonts-emoji
      symbola
      unifont
      unifont_upper
    ];
  };

  # Enable sound with pipewire.
  # TODO: systemwide?
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  environment.etc."pipewire/pipewire-pulse.conf.d/99-pulse-tcp.conf".text = ''
    pulse.properties = {
      server.address = [
        "unix:native"
        {
          address = "tcp:127.0.0.1:4713"
          client.access = "allowed"
        }
      ]
    }
  '';
  environment.etc."wireplumber/main.lua.d/99-disable-suspend.lua".text = ''
    table.insert(alsa_monitor.rules,
      {
        matches = {{{ "node.name", "matches", "alsa_output.*" }}};
        apply_properties = {
          ["dither.noise"] = 1;
          ["node.pause-on-idle"] = false;
          ["session.suspend-timeout-seconds"] = 0;
        }
      }
    )
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;

  # Enable Munin system monitor
  services.munin-node = {
    enable = true;
    extraConfig = ''
      cidr_allow 192.168.1.0/24
      cidr_allow fd85:f753:480f::/48
    '';
  };

  nix.settings.auto-optimise-store = true;
  system.autoUpgrade = {
    enable = false;
  };
}
