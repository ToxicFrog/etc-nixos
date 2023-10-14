{
  description = "flakes for all ancilla.ca nixos systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-local.url = "/home/rebecca/devel/nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-local }@inputs: {
    nixosConfigurations = let
      mkSystem = modules:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          inherit modules;
          specialArgs = {
            inherit inputs;
            unstable = (import nixpkgs-unstable { inherit system; config.allowUnfree = true; }).pkgs;
          };
        };
    in {
      # ancilla = mkSystem [ ./configuration.nix ];
      pladix = mkSystem [ ./systems/pladix/configuration.nix ];
      lots-of-cats = mkSystem [ ./systems/lots-of-cats/configuration.nix ];
      # TODO: isis, timelapse, lector
    };
  };
}
