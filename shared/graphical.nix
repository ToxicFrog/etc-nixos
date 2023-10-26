# Settings shared across machines with a graphical interface, i.e. not headless
# machines like ancilla.

{ config, pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    vlc
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
