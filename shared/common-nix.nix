# Common settings shared by all machines, specific to Nix and Nixpkgs, like the
# overlay and flake registry settings and configuration of the builders.

{ config, pkgs, inputs, ... }:

{
  # nixpkgs-aware command-not-found replacement, along with nix-locate command
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

  # Compatibility shim for running non-nixos binaries
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib libgcc.lib
      readline
      zlib libz
      fuse
      nss
      openal
      openvr
      freetype
      SDL SDL_ttf SDL_net SDL_gpu SDL_gfx SDL_sound SDL_mixer SDL_image
      SDL2 SDL2_ttf SDL2_net SDL2_gfx SDL2_sound SDL2_mixer SDL2_image
      xorg.libX11 xorg.libXext xorg.libXcursor xorg.libXrandr xorg.libxcb
      libGL
    ];
  };

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
      keep-derivations = true
      keep-outputs = true
    '';

    # Synchronize the flake registry with the flake.lock used to build the system.
    # see https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry = {
      nixos.flake = inputs.nixos;
      nixos-unstable.flake = inputs.nixos-unstable;
      # local.flake = inputs.nixpkgs-local; # TODO: doesn't work when bootstrapping
      # useful aliases
      nixpkgs.flake = inputs.nixos;
      unstable.flake = inputs.nixos-unstable;
    };
    # Set NIX_PATH to alias channel references like <nixpkgs> to paths we control
    # rather than to the actual channels...
    nixPath = [
      # These match the flakes above
      "nixos=/etc/channels/nixos"
      "nixos-unstable=/etc/channels/nixos-unstable"
      # "local=/etc/channels/nixpkgs-local" # TODO: doesn't work when bootstrapping
      # These are the aliases
      "nixpkgs=/etc/channels/nixos"
      "unstable=/etc/channels/nixos-unstable"
      # And these are additional NIX_PATH settings with no equivalent in the
      # flake registry.
      # "nixpkgs-overlays=/etc/nixos/shared/overlays"
      "nixpkgs-overlays=/etc/channels/overlays"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  # ...and then point those paths at the flake inputs, thus also synchronizing
  # channel references with flake.lock.
  environment.etc."channels/nixos".source = inputs.nixos.outPath;
  environment.etc."channels/nixpkgs".source = inputs.nixos.outPath;
  environment.etc."channels/nixos-unstable".source = inputs.nixos-unstable.outPath;
  environment.etc."channels/unstable".source = inputs.nixos-unstable.outPath;
  environment.etc."channels/overlays".source = ./overlays;
  # environment.etc."channels/nixpkgs-local".source = inputs.nixpkgs-local.outPath; # TODO: doesn't work when bootstrapping
}
