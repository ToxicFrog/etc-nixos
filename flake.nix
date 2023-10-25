{
  description = "flakes for all ancilla.ca nixos systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "flake:nixpkgs";
    nixpkgs-local.url = "/home/rebecca/devel/nixpkgs";
    munin-contrib = {
      url = "github:munin-monitoring/contrib/master";
      flake = false;
    };
    doomrl-server = {
      url = "/home/rebecca/devel/doomrl-server";
      flake = false;
    };
    crossfire-server = {
      url = "/home/rebecca/devel/crossfire-server";
      flake = false;
    };
    crossfire-arch = {
      url = "/home/rebecca/devel/crossfire-arch";
      flake = false;
    };
    crossfire-maps = {
      url = "/home/rebecca/src/crossfire-maps";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }@inputs: {
    nixosConfigurations = let
      mkSystem = extraModules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [ ./shared/common.nix ] ++ extraModules;
          specialArgs = {
            inherit inputs;
            unstable = (import nixpkgs-unstable { inherit system; config.allowUnfree = true; }).pkgs;
          };
        };
    in {
      ancilla = mkSystem [ ./configuration.nix ];
      pladix = mkSystem [ ./common/graphical.nix ./systems/pladix/configuration.nix ];
      lots-of-cats = mkSystem [ ./common/graphical.nix ./systems/lots-of-cats/configuration.nix ];
      # TODO: isis, timelapse, lector
    };
  };
}
