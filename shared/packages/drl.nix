{ stdenv, lib, fetchurl, writeShellScript,
  coreutils, libGL, ncurses, SDL2, SDL2_image, SDL2_mixer, SDL2_ttf, xorg, zlib,
  url ? "https://drl.chaosforge.org/file_download/44/drl-linux-0998.tar.gz",
  sha256 ? "sha256-EAgVqZr5pZkesOfKFg1PZS3O/Gz1S93JaJwk1ZWFLds=",
}:

let
  launcher = writeShellScript "drl-launcher" ''
    set -e
    declare -r DRL="$(${coreutils}/bin/dirname "$(${coreutils}/bin/realpath $0)")/../opt/doomrl"
    if ! [[ $DRL ]]; then
      >&2 echo "Error determining location of system DRL install!"
      exit 1
    else
      >&2 echo "Located system DRL at $DRL"
      >&2 echo "Setting up user files..."
    fi

    mkdir -p ~/.config/drl/{backup,config,modules,mortem,screenshot}
    cd ~/.config/drl
    ln -sf -t . "$DRL"/*.wad "$DRL"/*.txt "$DRL"/drl "$DRL"/drl_* "$DRL"/{mp3,wavhq}
    cp -n -t . "$DRL"/*.lua
    chmod u+w ~/.config/drl/*.lua

    if [[ $DISPLAY ]]; then
      exec ./drl "$@"
    else
      exec ./drl -console "$@"
    fi
  '';
in stdenv.mkDerivation {
  pname = "drl";
  version = "0.9.9.8";
  src = fetchurl { inherit url sha256; };
  libPath = lib.makeLibraryPath [
    libGL ncurses SDL2 SDL2_image SDL2_mixer SDL2_ttf xorg.libX11 zlib
  ];
  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p "$out/opt/" "$out/bin/"
    cp -a . "$out/opt/doomrl"

    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      --set-rpath "$libPath" \
      "$out/opt/doomrl/drl"

    cp -p ${launcher} "$out/bin/drl"
  '';
}
