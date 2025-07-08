{ pkgs, options, lib, inputs, factor-rewrap, makeWrapper, unstable, ... }:

let
  o = import ./overlays/crossfire.nix;
in {
  # Overlays for nixos itself, e.g. module replacements
  disabledModules = [
    # "config/users-groups.nix"
    "services/backup/borgbackup.nix"
    "services/monitoring/munin.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    # "${inputs.nixos-unstable}/nixos/modules/config/users-groups.nix"  # for linger
    "${inputs.nixos-unstable}/nixos/modules/services/monitoring/munin.nix"
  ];
  # Package overlays.
  nixpkgs.overlays = [
    (import ./overlays/doomrl-server.nix)
    (import ./overlays/dosage.nix)
    (import ./overlays/misc.nix)
    (import ./overlays/munin.nix)
    # N.b. we can't put any overlay that requires extra arguments in /shared/overlays
    # because those are also loaded via NIX_PATH, so each one needs to be a function
    # of two arguments to overlay set -- more complicated overlays that depend on
    # unstable or other inputs need to go here, or be imported from files in other
    # directories.
    (final: prev: {
      polaris = prev.callPackage ./overlays/packages/polaris.nix {};
      polaris-web = prev.callPackage ./overlays/packages/polaris-web.nix {};
      crossfire-jxclient = unstable.crossfire-jxclient;
      crossfire-gridarta = unstable.crossfire-gridarta;
      crossfire-client = unstable.crossfire-client;
      crossfire-server = unstable.crossfire-server.overrideAttrs (oldAttrs: {
        # version = "HEAD";
        # src = inputs.crossfire-server;
        # NIX_CFLAGS_COMPILE = "-g -O0";
        # NIX_CXXFLAGS_COMPILE = "-g -O0";
        # Reset maps every week rather than every 2h.
        # How do I get it to link against libxcrypt-legacy??
        # buildInputs = [ unstable.python3 unstable.libxcrypt-legacy ];
        postConfigure = ''
          sed -Ei 's,^#define MAP_MAXRESET .*,#define MAP_MAXRESET 604800,' include/config.h
          sed -Ei 's,^#define MAP_DEFAULTRESET .*,#define MAP_DEFAULTRESET 604800,' include/config.h
        '';
        # hardeningDisable = [ "all" ];
      });
    })
  ];
}
