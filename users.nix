{ config, pkgs, ... }:

let
  accounts = (import ./secrets/users.nix { config = config; pkgs = pkgs; });
in {
  programs.zsh.enable = true;
  users.mutableUsers = false;
  users.enforceIdUniqueness = false;

  users.groups.linger = {};
  system.activationScripts.linger = ''
    rm -rf /var/lib/systemd/linger
    mkdir -p /var/lib/systemd/linger
    for user in $(cat /etc/group | grep ^linger | cut -d: -f4- | tr "," " "); do
      touch /var/lib/systemd/linger/$user
    done
  '';

  users.users = accounts;
}
