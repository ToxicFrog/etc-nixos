{
  description = "flakes for all ancilla.ca nixos systems";

  # "nixos" points to nixos stable
  # "nixos-unstable" points to unstable
  # in common-nix, these are also aliased to <nixpkgs> and <unstable> respectively,
  # as both channels and flakes.
  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-local.url = "/home/bex/src/nixpkgs";  # TODO: doesn't work when bootstrapping

    # Nixpkgs patches
    nixpkgs-factor-rewrap.url = "github:spacefrogg/nixpkgs/factor-rewrap";

    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.nixpkgs.follows = "nixos";
    };

    # Non-nixos upstreams
    munin-contrib = {
      url = "github:munin-monitoring/contrib/master";
      flake = false;
    };

    bizhawk-src = {
      url = "github:TASEmulators/BizHawk/master";
      flake = false;
    };
    # Local inputs
    # Uncomment the git+ url to use latest commit, or the plain path to use
    # whatever is in the worktree.
    doomrl-server = {
      url = "/home/bex/devel/doomrl-server";
      flake = false;
    };
  };

  outputs = {
    self, nixos, nixos-unstable, lix-module, bizhawk-src, ...
  }@inputs: let
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-33.4.11"  # needed for itch.io client
        "olm-3.2.16"  # needed by ancilla mautrix bridges
        "dotnet-sdk-6.0.428" # EOL, TODO: figure out what uses this
        "dotnet-runtime-6.0.36" # ditto
        "freeimage-3.18.0-unstable-2024-04-18" # needed by slade
        "freeimage-unstable-2021-11-01" # ditto
      ];
    };
    system = "x86_64-linux";
    commonModules = [
      { nixpkgs.config = config; }
      ./shared/common.nix
      lix-module.nixosModules.default
    ];
    secrets = (import ./secrets/default.nix);
    # nixpkgs = (import nixos { inherit system config; }).pkgs;
    nixpkgs-unstable = (import nixos-unstable { inherit system config; }).pkgs;
    mkSystem = extraModules:
      nixos.lib.nixosSystem rec {
        inherit system;
        modules = commonModules ++ extraModules;
        specialArgs = {
          inherit inputs secrets;
          unstable = nixpkgs-unstable;
        };
      };
  in {
    nixosConfigurations = {
      ancilla = mkSystem [ ./shared/bex-packages.nix ./ancilla/configuration.nix ];
      durandal = mkSystem [ ./shared/graphical.nix ./shared/bex-packages.nix ./durandal/configuration.nix ];
      thoth = mkSystem [ ./shared/graphical.nix ./shared/bex-packages.nix ./thoth/configuration.nix ];
      thoth-installer = mkSystem [
        ./shared/graphical.nix
        ./thoth/installer.nix
      ];
      iscsi-target = mkSystem [
        ./misc/iscsi-target.nix
      ];
      installer = mkSystem [ ./misc/installer.nix ];
      pladix = mkSystem [ ./shared/graphical.nix ./shared/alex-gaming.nix ./pladix/configuration.nix ];
      lots-of-cats = mkSystem [ ./shared/graphical.nix ./shared/alex-gaming.nix ./lots-of-cats/configuration.nix ];
      isis = mkSystem [ ./isis/configuration.nix ];
      # TODO: timelapse, lector
    };
  };
}
