{ ... }:
{
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./overrides.nix)
    (import ./skicka/default.nix)
    (import ./timg.nix)
  ];
}
