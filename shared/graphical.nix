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
    layout = "us";
    xkbVariant = "";
    # Ctrl on capslock, alt is both alt and meta, compose is on left winkey
    xkbOptions = "caps:ctrl_modifier,altwin:meta_alt,compose:lwin";
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
    # libinput.enable = false;
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    ark
    git-cola
    libnotify
    vlc
    xscreensaver
  ];

  fonts = {
    fontDir.enable = true;
    enableDefaultFonts = true;
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
      nerdfonts
    ];
  };
}
