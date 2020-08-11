{ pkgs, options, ... }:
{
  # Proxy NIX_PATH to point at the same overlays defined in nixpkgs.overlays
  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nixos/overlays/compat/" ];
  # Turn off these modules and replace them with our own versions with unmerged fixes.
  disabledModules = [
    "services/backup/borgbackup.nix"
    "security/acme.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    ./modules/acme.nix
  ];
  # Actual overlays.
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (import ./skicka)
    (self: super: {
      timg = self.callPackage ./timg {};
      tiv = self.callPackage ./tiv {};
      slashem9 = self.callPackage ./slashem9/slashem9.nix {};
      recoll = super.recoll.override { withGui = false; };
      airsonic = (self.callPackage ./airsonic {}).overrideAttrs (_: {
        patches = [./airsonic/podcast-order.patch];
      });
    })
  ];
}
