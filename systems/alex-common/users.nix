{ config, pkgs, ... }:

let
  users = (import ../../secrets/users.nix { config = config; pkgs = pkgs; });
in {
  users.users.pladix = {
    isNormalUser = true;
    description = "pladix role account";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
    shell = pkgs.zsh;
  };
  users.users.root = users.root;
  users.users.alex = users.alex // {
    createHome = true;
    extraGroups = users.alex.extraGroups ++ [ "adbusers" ];
  };
}
