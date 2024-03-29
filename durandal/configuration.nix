# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, unstable, secrets, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users = {
    root = (secrets.thoth.users { inherit pkgs; }).root;
    bex = (secrets.thoth.users { inherit pkgs; }).bex // { createHome = true; };
  };
  networking = {
    hostName = "durandal";
    domain = "ancilla.ca";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "bex";
  };

  programs.steam.enable = true;
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    digikam
    syncthing qsyncthingtray
    vscode
    yakuake
  ];

  environment.etc."wireplumber/main.lua.d/99-disable-suspend.lua".text = ''
    table.insert(alsa_monitor.rules,
      {
        matches = {{{ "node.name", "matches", "alsa_output.*" }}};
        apply_properties = {
          ["dither.noise"] = 2;
          ["node.pause-on-idle"] = false;
          ["session.suspend-timeout-seconds"] = 0;
        }
      }
    )
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

