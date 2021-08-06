{ pkgs, options, lib, ... }:
{
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
      weechat-unwrapped = super.weechat-unwrapped.override { perl = super.perl530; };
      # jellyfin = super.jellyfin.override { ffmpeg = super.ffmpeg-full; };
      etcd = super.etcd_3_4;
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
      mavenix = super.callPackage /home/rebecca/src/mavenix {};
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
