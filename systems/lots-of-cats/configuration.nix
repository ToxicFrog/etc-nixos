{ config, pkgs, modulesPath, ... }:

{
  system.stateVersion = "20.09"; # Did you read the comment?

  imports =
    [
      ./hardware-configuration.nix
      ../alex-common/default.nix
      ../../services/syncthing.nix
    ];

  networking = {
    hostName = "lots-of-cats";
    domain = "ancilla.ca";
    networkmanager.enable = true;
  };

  #console.font = "latarcyrheb-sun32";
  console.keyMap = "us";

  networking.firewall.enable = false;

  # Fix for HDMI audio going away after suspend
  # powerManagement.resumeCommands = ''
  #   sleep 2
  #   ${pkgs.sudo}/bin/sudo -u pladix pacmd set-card-profile 0 output:hdmi-stereo
  # '';

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  # services.xserver.displayManager.sddm.autoLogin.relogin = true;
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "pladix";
  # };
  services.xserver.desktopManager.plasma5.enable = true;
  systemd.services.display-manager.wants = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];
  systemd.services.display-manager.after = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];
}
