self: super:
with super.lib;
let
  # Load the system config and get the `nixpkgs.overlays` option
  # overlay-dir = /etc/nixos/overlays;
  #overlay-dir = pkgs.copyPathToStore ../overlays;
  # overlays = (import "${overlay-dir}/default.nix" {}).config.nixpkgs.overlays;
  overlays = (import <nixpkgs/nixos> { configuration = "/etc/nix-overlays/default.nix"; }).config.nixpkgs.overlays;
in
  # Apply all overlays to the input of the current "main" overlay
  foldl' (flip extends) (_: super) overlays self
