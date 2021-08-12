# Configuration for remote desktop session

{ config, pkgs, lib, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  # Needed for VNC
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
      noto-fonts-emoji
      symbola
      unifont
      unifont_upper
    ];
  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };


  #programs.turbovnc.ensureHeadlessSoftwareOpenGL = true;
  services.xserver = {
    desktopManager.lxqt.enable = true;
    enable = true;
    extraConfig = ''
      Section "DRI"
        Mode 0666
      EndSection
    '';
    #autostart = false;
  };
#  environment.systemPackages =
#    pkgs.lxqt.preRequisitePackages ++
#    pkgs.lxqt.corePackages ++
#    pkgs.lxqt.optionalPackages;

  systemd.user.services.vncdesktop = let
    xinit = pkgs.writeScript "vncdesktop-xinit" ''
      export XDG_CONFIG_DIRS="$XDG_CONFIG_DIRS''${XDG_CONFIG_DIRS:+:}${config.system.path}/share"
      export PATH="$PATH:/run/current-system/sw/bin"
      exec ${pkgs.lxqt.lxqt-session}/bin/startlxqt
    '';
  in {
    description = "Headless VNC desktop";
    after = ["network-online.target" "local-fs.target"];
    #preStart = "mkdir -p $HOME/Games/Bitburner";
    serviceConfig.ExecStart = "${pkgs.turbovnc}/bin/vncserver -disconnect -geometry 1024x768 -fg -autokill -xstartup ${xinit} -localhost";
    path = with pkgs; [perl xorg.xauth ];
  };
}
