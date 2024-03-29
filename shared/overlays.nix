{ pkgs, options, lib, inputs, ... }:
{
  # Overlays for nixos itself, e.g. module replacements
  disabledModules = [
    "config/users-groups.nix"
    "services/backup/borgbackup.nix"
    "services/monitoring/munin.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    (lib.modules.mkAliasOptionModule [ "fonts" "packages" ] [ "fonts" "fonts" ])
    "${inputs.nixpkgs-unstable}/nixos/modules/config/users-groups.nix"  # for linger
    # TODO: switch to nixpkgs-unstable once the PR lands there
    "${inputs.nixpkgs-local}/nixos/modules/services/monitoring/munin.nix"
  ];
  # Package overlays.
  nixpkgs.overlays = [
    # (import ./overlays/crossfire.nix inputs)
    # (import ./overlays/doomrl-server.nix inputs.doomrl-server)
    (import ./overlays/crossfire.nix)
    (import ./overlays/doomrl-server.nix)
    (import ./overlays/dosage.nix)
    (import ./overlays/factor-lang.nix)
    (import ./overlays/misc.nix)
    (import ./overlays/munin.nix)
  ];
}
