{ pkgs, options, ... }:
{
  # Proxy NIX_PATH to point at the same overlays defined in nixpkgs.overlays
  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nixos/overlays/compat/" ];
  environment.systemPackages = with pkgs; [
    (callPackage ./timg/default.nix {})
    (callPackage ./tiv/default.nix {})
    (callPackage ./slashem9/slashem9.nix {})
  ];
  disabledModules = [
    "services/backup/borgbackup.nix"
    "security/acme.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    ./modules/acme.nix
  ];
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (import ./skicka)
    (self: super: {
      recoll = super.recoll.override { withGui = false; };
      airsonic = (self.callPackage ./airsonic {}).overrideAttrs (_: {
        patches = [./airsonic/podcast-order.patch];
      });
    })
  ];
}
