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
    /home/rebecca/devel/nixpkgs/nixos/modules/services/games/crossfire-server.nix
    /home/rebecca/devel/nixpkgs/nixos/modules/services/games/deliantra-server.nix
  ];
  # Actual overlays.
  nixpkgs.overlays = [
    (import ./doomrl.nix)
    (import ./doomrl-server.nix)
    (import ./dosbox-debug.nix)
    (import ./misc.nix)
    (import ./skicka)
    (self: super: {
      etcd = super.etcd_3_4;
      slashem9 = super.callPackage ./slashem9/slashem9.nix {};
      weechat = super.weechat.override {
        configure = { availablePlugins, ... }: {
          scripts = with unstable.pkgs.weechatScripts; [
            unstable.pkgs.weechatScripts.weechat-matrix
            pkgs.weechatScripts.multiline
          ];
        };
      };
      # TODO: crossfire should still include the patches for compiled-in config changes
      youtube-dlc = super.youtube-dl.overrideAttrs (attrs: rec {
        name = "youtube-dl";
        pname = "youtube-dlc";
        version = "2020.11.07";

        src = super.fetchFromGitHub {
          owner = "blackjack4494";
          repo = "yt-dlc";
          rev = "651bae3d231640fa9389d4e8d24412ad75f01843";
          sha256 = "0zmp8yjz8kf0jwbf2cy3l0mf0252kcc4qwmnh6iq0bbilbknhhwv";
        };
        postInstall = ''
          cd $out/bin
          ln -s youtube-dlc youtube-dl
        '';
      });
      youtube-dl = super.youtube-dl.overrideAttrs (attrs: rec {
        version = "2021.03.25";
        src = super.fetchurl {
          url = "https://youtube-dl.org/downloads/latest/youtube-dl-2021.03.25.tar.gz";
          sha256 = "0ps8ydx4hbj6sl0m760zdm9pvhccjmwvx680i4akz3lk4z9wy0x3";
        };
      });
      recoll = super.recoll.override { withGui = false; };
      airsonic = super.airsonic.overrideAttrs (_: rec {
        version = "11.0.20210803";
        name = "airsonic-advanced-${version}";
        src = /srv/airsonic/airsonic-advanced-11.0.20210803.war;
      });
      jackett = super.jackett.overrideAttrs (oldAttrs: rec {
        version = "0.17.946";
        src = super.fetchurl {
          url = "https://github.com/Jackett/Jackett/releases/download/v${version}/Jackett.Binaries.Mono.tar.gz";
          sha256 = "1cc3mslg8w2nv8kxg24c6grc742ia12rghrdl4narz44qcy7k682";
        };
        installPhase = ''
          mkdir -p $out/{bin,share/${oldAttrs.pname}-${version}}
          cp -r * $out/share/${oldAttrs.pname}-${version}
          makeWrapper "${pkgs.mono}/bin/mono" $out/bin/Jackett \
            --add-flags "$out/share/${oldAttrs.pname}-${version}/JackettConsole.exe" \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (with pkgs; [ curl icu60 openssl zlib ])}
        '';
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
      # jellyfin = super.jellyfin.overrideAttrs (oldAttrs: rec {
      #   version = "10.6.2";
      #   src = super.fetchurl {
      #     url = "https://repo.jellyfin.org/releases/server/portable/versions/stable/combined/${version}/jellyfin_${version}.tar.gz";
      #     sha256 = "16yib2k9adch784p6p0whgfb6lrjzwiigg1n14cp88dx64hyhxhb";
      #   };
      # });
    })
  ];
}
