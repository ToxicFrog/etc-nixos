{ config, pkgs, ... }:

let
  accounts = (import ./secrets/users.nix { config = config; pkgs = pkgs; });
in {
  programs.zsh.enable = true;
  users.mutableUsers = false;
  users.enforceIdUniqueness = false;
  users.users = accounts;
}
