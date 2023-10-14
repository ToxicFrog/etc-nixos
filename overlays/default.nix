{ pkgs, options, lib, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
  localpkgs = (import /home/rebecca/devel/nixpkgs {});
in {
  # Proxy NIX_PATH to point at the same overlays defined in nixpkgs.overlays
  # TODO: this means that overlays only take effect on nixos-rebuild. It would be nice
  # if they took effect (for nix-shell etc) immediately...
  nix.nixPath =
    options.nix.nixPath.default ++ [
      "nixpkgs-overlays=/etc/nix-overlays/compat"
      "nixpkgs-devel=/home/bex/devel/nixpkgs"
    ];
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
    (import ./crossfire.nix)
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosage.nix)
    (import ./misc.nix)
    (self: super: {
      etcd = super.etcd_3_4;
      slashem9 = super.callPackage ./slashem9/slashem9.nix {};
      sigal = super.sigal.overrideAttrs (_: {
        patches = [
          (super.fetchpatch {
            url = "https://github.com/saimn/sigal/commit/0bf932935b912f5a4b594182b347f4698a0052dc.patch";
            sha256 = "sha256-h9m5o2RXkNiN36hF97iLCr6JP8+dcGYWM8N0sALFnvw=";
          })
        ];
      });
      weechat = super.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with pkgs.weechatScripts; [ weechat-matrix multiline ];
        };
      };
      recoll = super.recoll.override { withGui = false; };
      airsonic = super.airsonic.overrideAttrs (_: rec {
        version = "11.0.2-kagemomiji";
        name = "airsonic-advanced-${version}";
        src = super.fetchurl {
          url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/11.0.2/airsonic.war";
          sha256 = "PgErtEizHraZgoWHs5jYJJ5NsliDd9VulQfS64ackFo=";
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
    })
  ];
}
