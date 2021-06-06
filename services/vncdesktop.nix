# Configuration for remote desktop session

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

  services.xserver.desktopManager.lxqt.enable = true;
#  environment.systemPackages =
#    pkgs.lxqt.preRequisitePackages ++
#    pkgs.lxqt.corePackages ++
#    pkgs.lxqt.optionalPackages;

  systemd.user.services.vncdesktop = let
    xinit = pkgs.writeScript "vncdesktop-xinit" ''
      export XDG_CONFIG_DIRS="$XDG_CONFIG_DIRS''${XDG_CONFIG_DIRS:+:}${config.system.path}/share"
      export PATH="$PATH:/run/current-system/sw/bin"
      exec ${pkgs.lxqt.lxqt-session}/bin/startlxqt
      #${pkgs.ratpoison}/bin/ratpoison &
      #exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      #  --user-data-dir=$HOME/Games/Bitburner
    '';
  in {
    description = "Headless VNC desktop";
    after = ["network-online.target" "local-fs.target"];
    #preStart = "mkdir -p $HOME/Games/Bitburner";
    serviceConfig.ExecStart = "${pkgs.tigervnc}/bin/vncserver -geometry 1024x768 -fg -autokill -xstartup ${xinit} -localhost";
    path = with pkgs; [perl xorg.xauth ];
  };
}
