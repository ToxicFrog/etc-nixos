{ ... }:
{
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
