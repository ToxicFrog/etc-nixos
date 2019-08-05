# Configuration for headless Bitburner

{ config, pkgs, lib, ... }:

{
  # Needed for VNC
  fonts = {
    enableDefaultFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.cache32Bit = true;
    fonts = with pkgs; [
      corefonts
      google-fonts
      gentium
      inconsolata-lgc
      noto-fonts-emoji
      symbola
      unifont
      unifont_upper
    ];
  };

  systemd.user.services.bitburner = let
    xinit = pkgs.writeScript "bitburner-xinit" ''
      ${pkgs.ratpoison}/bin/ratpoison &
      exec ${pkgs.google-chrome}/bin/google-chrome-stable \
        --user-data-dir=$HOME/Games/Bitburner \
        https://danielyxie.github.io/bitburner/
    '';
  in {
    description = "Headless Bitburner session running in VNC";
    after = ["network-online.target" "local-fs.target"];
    preStart = "mkdir -p $HOME/Games/Bitburner";
    serviceConfig.ExecStart = "${pkgs.tigervnc}/bin/vncserver -geometry 1024x768 -fg -autokill -xstartup ${xinit} -localhost";
    path = with pkgs; [perl xorg.xauth];
  };
}
