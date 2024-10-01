# Settings shared across machines with a graphical interface, i.e. not headless
# machines like ancilla.

{ config, pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Enable X11 and KDEPlasma
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    # Ctrl on capslock, alt is both alt and meta, compose is on left winkey
    xkb.options = "caps:ctrl_modifier,altwin:meta_alt,compose:lwin";
    desktopManager.plasma5.enable = lib.mkDefault true;
    # libinput.enable = false;
  };
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    # wayland.enable = true;
    # settings.General.DisplayServer = "x11";
  };
  # Enable XDG desktop portal for GTK programs like VSCode, so that they will
  # use native (i.e. Qt) file pickers and stuff.
  environment.sessionVariables.GTK_USE_PORTAL = "1";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio = lib.mkDefault {
    enable = false;
    support32Bit = false;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ark
    git-cola
    kitty
    libnotify
    tdrop
    vlc
    xorg.libX11  # for XCompose locale data
    xscreensaver
  ];

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    fontconfig.localConf = ''
      <selectfont>
        <rejectfont>
          <pattern>
            <patelt name="family">
              <string>FreeMono</string>
            </patelt>
          </pattern>
          <pattern>
            <patelt name="family">
              <string>FreeSans</string>
            </patelt>
          </pattern>
          <pattern>
            <patelt name="family">
              <string>FreeSerif</string>
            </patelt>
          </pattern>
        </rejectfont>
      </selectfont>
    '';
    packages = with pkgs; [
      corefonts
      (google-fonts.override { fonts = [ "Cousine" ]; })
      gentium
      inconsolata-lgc
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      symbola
      unifont
      unifont_upper
      (nerdfonts.override { fonts = [ "Cousine" "Hasklig" "NerdFontsSymbolsOnly" "FiraCode" ]; })
    ];
  };
}
