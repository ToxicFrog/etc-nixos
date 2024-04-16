{
  description = "flakes for all ancilla.ca nixos systems";

  # "nixos" points to nixos stable
  # "nixos-unstable" points to unstable
  # in common-nix, these are also aliased to <nixpkgs> and <unstable> respectively,
  # as both channels and flakes.
  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-local.url = "/home/bex/devel/nixpkgs";

    # Nixpkgs patches
    nixpkgs-factor-rewrap.url = "github:spacefrogg/nixpkgs/factor-rewrap";

    # Non-nixos upstreams
    mstream = {
      url = "github:IrosTheBeggar/mstream/master";
      flake = false;
    };
    munin-contrib = {
      url = "github:munin-monitoring/contrib/master";
      flake = false;
    };

    # Local inputs
    doomrl-server = {
      url = "/home/bex/devel/doomrl-server";
      flake = false;
    };
    crossfire-server = {
      url = "/home/bex/devel/crossfire-server";
      flake = false;
    };
    crossfire-arch = {
      url = "/home/bex/devel/crossfire-arch";
      flake = false;
    };
    crossfire-maps = {
      url = "/home/bex/src/crossfire-maps";
      flake = false;
    };
  };

  outputs = { self, nixos, nixos-unstable, ... }@inputs: {
    nixosConfigurations = let
      mkSystem = extraModules:
        nixos.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [ ./shared/common.nix ] ++ extraModules;
          specialArgs = {
            inherit inputs;
            unstable = (import nixos-unstable { inherit system; config.allowUnfree = true; }).pkgs;
            factor-rewrap = (import inputs.nixpkgs-factor-rewrap { inherit system; config.allowUnfree = true; }).pkgs;
            secrets = (import ./secrets/default.nix);
          };
        };
    in {
      ancilla = mkSystem [ ./ancilla/configuration.nix ];
      durandal = mkSystem [ ./shared/graphical.nix ./shared/alex-gaming.nix ./durandal/configuration.nix ];
      thoth = mkSystem [ ./shared/graphical.nix ./thoth/configuration.nix ];
      thoth-installer = mkSystem [
        ./shared/graphical.nix
        ./thoth/installer.nix
      ];
      iscsi-target = mkSystem [
        ./iscsi-target.nix
      ];
      installer = mkSystem [ ./installer.nix ];
      pladix = mkSystem [ ./shared/graphical.nix ./shared/alex-gaming.nix ./pladix/configuration.nix ];
      lots-of-cats = mkSystem [ ./shared/graphical.nix ./shared/alex-gaming.nix ./lots-of-cats/configuration.nix ];
      isis = mkSystem [ ./isis/configuration.nix ];
      # TODO: timelapse, lector
    };
  };
}
