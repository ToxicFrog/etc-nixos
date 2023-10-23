{ pkgs, options, lib, inputs, ... }:
{
  # Overlays for nixos itself, e.g. module replacements
  imports = [
    ./nixos.nix
  ];
  # Actual overlays.
  nixpkgs.overlays = [
    (import ./crossfire.nix inputs)
    (import ./doomrl.nix)
    (import ./doomrl-server.nix inputs.doomrl-server)
    (import ./dosage.nix)
    (import ./misc.nix)
    (self: super: {
      etcd = super.etcd_3_4; # todo: try upgrading to latest stable (3.5)
      slashem9 = super.callPackage ../packages/slashem9/slashem9.nix {};
      weechat = super.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with pkgs.weechatScripts; [ weechat-matrix multiline ];
        };
      };
      # This gets regular updates but I need to replace it with gonic if and when I can.
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
