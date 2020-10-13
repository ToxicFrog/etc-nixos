{ pkgs, options, ... }:
{
  # Proxy NIX_PATH to point at the same overlays defined in nixpkgs.overlays
  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nixos/overlays/compat/" ];
  # Turn off these modules and replace them with our own versions with unmerged fixes.
  disabledModules = [
    "services/backup/borgbackup.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
    ./modules/crossfire-server.nix
  ];
  # Actual overlays.
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (import ./skicka)
    (self: super: {
      timg = super.callPackage ./timg {};
      tiv = super.callPackage ./tiv {};
      slashem9 = super.callPackage ./slashem9/slashem9.nix {};
      crossfire-arch = super.callPackage ./crossfire/crossfire-arch.nix {
        version = "latest"; rev = 21388;
        sha256 = "0385icnzvxm2pkjrkr7bikm7vydwx94xqii9jzq3li864wmcq6rk";
      };
      crossfire-maps = super.callPackage ./crossfire/crossfire-maps.nix {
        version = "latest"; rev = 21388;
        sha256 = "05g7lr4yzcb98q698b8h44h7rw6h1kbfbhn2nqkhn3ymr5j6fcr2";
      };
      crossfire-server-latest = super.callPackage ./crossfire/crossfire-server.nix {
        version = "latest"; rev = 21388;
        sha256 = "09chf8sqw5w7sm02k13kcrvh4fibsmj31cxp8gnprk9fcj581fc3";
        maps = self.crossfire-maps;
        arch = self.crossfire-arch;
      };
      recoll = super.recoll.override { withGui = false; };
      # airsonic = (super.callPackage ./airsonic {}).overrideAttrs (_: {
      #   patches = [./airsonic/podcast-order.patch];
      # });
      airsonic = super.airsonic.overrideAttrs (_: rec {
        version = "10.6.0";
        name = "airsonic-advanced-${version}";
        src = /srv/airsonic/airsonic-advanced-10.6.0.war;
      });
      mavenix = super.callPackage /home/rebecca/src/mavenix {};
      jackett = super.jackett.overrideAttrs (oldAttrs: rec {
        version = "0.16.1021";
        src = super.fetchurl {
          url = "https://github.com/Jackett/Jackett/releases/download/v${version}/Jackett.Binaries.LinuxAMDx64.tar.gz";
          sha256 = "1i0bs24q1lkxajz05fm8z5m33l1n4dsygfr2v1rqd3w2y2nykg43";
        };
      });
      jellyfin = super.jellyfin.overrideAttrs (oldAttrs: rec {
        version = "10.6.2";
        src = super.fetchurl {
          url = "https://repo.jellyfin.org/releases/server/portable/versions/stable/combined/${version}/jellyfin_${version}.tar.gz";
          sha256 = "16yib2k9adch784p6p0whgfb6lrjzwiigg1n14cp88dx64hyhxhb";
        };
      });
    })
  ];
}
