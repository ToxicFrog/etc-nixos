{ pkgs, options, lib, nixpkgs-unstable, ... }:

{
  disabledModules = [
    "config/users-groups.nix"
    "services/backup/borgbackup.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    "${nixpkgs-unstable}/nixos/modules/config/users-groups.nix"
  ];
}
