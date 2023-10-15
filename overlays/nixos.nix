{ pkgs, options, lib, inputs, ... }:

{
  disabledModules = [
    "config/users-groups.nix"
    "services/backup/borgbackup.nix"
    "services/monitoring/munin.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    "${inputs.nixpkgs-unstable}/nixos/modules/config/users-groups.nix"
    "${inputs.nixpkgs-local}/nixos/modules/services/monitoring/munin.nix"
  ];
}
