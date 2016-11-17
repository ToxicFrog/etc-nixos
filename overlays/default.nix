{ ... }:
{
  nixpkgs.overlays = [
    (import ./skicka/default.nix)
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./overrides.nix)
  ];
}
