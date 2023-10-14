{ pkgs, options, lib, inputs, ... }:

{
  disabledModules = [
    "config/users-groups.nix"
    "services/backup/borgbackup.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    "${inputs.nixpkgs-unstable}/nixos/modules/config/users-groups.nix"
  ];
}
