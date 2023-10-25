# Common settings shared by all machines, specific to Nix and Nixpkgs, like the
# overlay and flake registry settings and configuration of the builders.

{ config, pkgs, inputs, ... }:

{
  # Compatibility shim for running non-nixos binaries
  programs.nix-ld.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Settings for Nix itself.
  nix = {
    gc = { automatic = true; options = "--delete-older-than 60d"; };
    settings = {
      sandbox = true;
      auto-optimise-store = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # Synchronize the flake registry with the flake.lock used to build the system.
    # see https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      unstable.flake = inputs.nixpkgs-unstable;
      local.flake = inputs.nixpkgs-local;
    };
    # Set NIX_PATH to alias channel references like <nixpkgs> to paths we control
    # rather than to the actual channels...
    nixPath = [
      "nixpkgs=/etc/channels/nixpkgs"
      "nixpkgs-overlays=/etc/nixos/overlays"
      "unstable=/etc/channels/nixpkgs-unstable"
      "local=/etc/channels/nixpkgs-local"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  # ...and then point those paths at the flake inputs, thus also synchronizing
  # channel references with flake.lock.
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
  environment.etc."channels/nixpkgs-unstable".source = inputs.nixpkgs-unstable.outPath;
  environment.etc."channels/nixpkgs-local".source = inputs.nixpkgs-local.outPath;
}
