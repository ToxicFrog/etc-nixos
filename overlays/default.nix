{ ... }:
{
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (import ./skicka)
  ];
}
