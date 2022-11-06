{ pkgs, options, lib, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
  localpkgs = (import /home/rebecca/devel/nixpkgs {});
in {
  # Proxy NIX_PATH to point at the same overlays defined in nixpkgs.overlays
  # TODO: this means that overlays only take effect on nixos-rebuild. It would be nice
  # if they took effect (for nix-shell etc) immediately...
  nix.nixPath =
    # let trampoline = ./compat;
    options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nix-overlays/compat" ];
  # Copy this into /etc/nix-overlays so everyone can read it.
  environment.etc.nix-overlays = {
    source = ./../overlays;
  };
  # Turn off these modules and replace them with our own versions with unmerged fixes.
  disabledModules = [
    "services/backup/borgbackup.nix"
  ];
  imports = [
    ./modules/borgbackup.nix
  ];
  # Actual overlays.
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (self: super: {
      etcd = super.etcd_3_4;
      slashem9 = super.callPackage ./slashem9/slashem9.nix {};
      sigal = super.sigal.overrideAttrs (oldAttrs: rec {
        version = "2.3-alpha";
        src = super.fetchFromGitHub {
          owner = "saimn";
          repo = "sigal";
          rev = "246aed53ff2d29d680cc81929e59f19023e463bb";
          sha256 = "1nxznibyn5g9fd1aksfjmcqrjhghi1zfbyrdlb0sjaxkdsjn9mnv";
        };
        patchPhase = ''
          sed -Ei 's,THEMES_PATH = ,THEMES_PATH = os.getenv("SIGAL_THEMES_PATH") or ,' sigal/writer.py
        '';
        propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [self.python3Packages.setuptools];
        pytestCheckPhase = "true"; # skip tests at HEAD
      });
      weechat = super.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with pkgs.weechatScripts; [ weechat-matrix multiline ];
        };
      };
      recoll = super.recoll.override { withGui = false; };
      airsonic = super.airsonic.overrideAttrs (_: rec {
        version = "11.0.0-SNAPSHOT.20220418221611";
        name = "airsonic-advanced-${version}";
        src = super.fetchurl {
          url = "https://github.com/airsonic-advanced/airsonic-advanced/releases/download/11.0.0-SNAPSHOT.20220418221611/airsonic.war";
          sha256 = "06mxx56c5i1d9ldcfznvib1c95066fc1dy4jpn3hska2grds5hgh";
        };
      });
      openxcom = super.openxcom.overrideAttrs (oldAttrs: rec {
        version = "7.0-oxce-2021.03.13";
        src = super.fetchFromGitHub {
          #owner = "OpenXcom"; repo = "OpenXcom";
          #rev = "4ccb8a67a775dfc81244cf9a4bdb73584815ca51";
          #sha256 = "1rd8paqyzds8qrggwy0p3k1f9gg7cvvsscdq0nb01zadhbrn939i";
          owner = "MeridianOXC"; repo = "OpenXcom";
          rev = "08d9eb908265b1fed482ff388d1ea7e8102d758f";
          sha256 = "0xwhzcqp1lhzralmipwk0xx2p94pa2gckh39cs4bg67cpqp3rnq0";
        };
        nativeBuildInputs = with super; [ cmake pkg-config ];
      });
      # jellyfin = super.jellyfin.override { ffmpeg = super.ffmpeg-full; };
    })
  ];
}
