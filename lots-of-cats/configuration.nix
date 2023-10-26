{ config, pkgs, modulesPath, ... }:

let
  users = (import ../secrets/users.nix { config = config; pkgs = pkgs; });
in {
  system.stateVersion = "20.09"; # Did you read the comment?

  imports =
    [
      ./hardware-configuration.nix
      ../ancilla/services/syncthing.nix
    ];

  networking = {
    hostName = "lots-of-cats";
    domain = "ancilla.ca";
    networkmanager.enable = true;
  };

  #console.font = "latarcyrheb-sun32";
  console.keyMap = "us";

  networking.firewall.enable = false;

  users.users.root = users.root;
  users.users.alex = users.alex // { createHome = true; };

  # Fix for HDMI audio going away after suspend
  # powerManagement.resumeCommands = ''
  #   sleep 2
  #   ${pkgs.sudo}/bin/sudo -u pladix pacmd set-card-profile 0 output:hdmi-stereo
  # '';

  # Enable the X11 windowing system.
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.autoLogin.relogin = true;
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "pladix";
  # };
  systemd.services.display-manager.wants = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];
  systemd.services.display-manager.after = [ "systemd-user-sessions.service" "multi-user.target" "network-online.target" ];
}
