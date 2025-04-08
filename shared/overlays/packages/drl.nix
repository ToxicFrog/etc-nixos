{ stdenv, lib, fetchzip, fetchFromGitHub, writeShellScript,
  coreutils,
  fpc,
  git,
  libGL,
  lua5_1,
  ncurses,
  SDL2,
  SDL2_image,
  SDL2_mixer,
  SDL2_ttf,
  xorg,
  zlib,
  url ? "https://drl.chaosforge.org/file_download/44/drl-linux-0998.tar.gz",
  sha256 ? "sha256-EAgVqZr5pZkesOfKFg1PZS3O/Gz1S93JaJwk1ZWFLds=",
}:

let
  # Actual game source code.
  src = fetchFromGitHub {
    owner = "chaosforgeorg";
    repo = "doomrl";
    rev = "0_9_9_8a";
    hash = "sha256-4d8XIujyKA09c7h3zXvViRopY7sf2fp380WVHGVuox0=";
    leaveDotGit = true;
  };

  # Valkyrie library needed for build.
  fpcvalkyrie = fetchFromGitHub {
    owner = "chaosforgeorg";
    repo = "fpcvalkyrie";
    rev = "0_9_0a";
    hash = "sha256-a/JbYmyla1wpbRhwNbSHvuWHOab894td5uQY6fbH2fs=";
    leaveDotGit = true;
  };

  # Sound and music aren't included in the repo, only in the zip with the binary
  # distribution -- so we fetch that, then replace the executable with one we
  # build ourself.
  release = fetchzip {
    name = "doomrl-release";
    inherit url;
    hash = "sha256-51xw25WLNOhTmPhi3mZHvrw36RLAaUaFwtEYB4EBgHc=";
  };

  runtimeDeps = [
    libGL ncurses SDL2 SDL2_image SDL2_mixer SDL2_ttf xorg.libX11 zlib
  ];
  launcher = writeShellScript "drl-launcher" ''
    set -e
    export PATH="''${PATH}:${coreutils}/bin"
    declare -r DRL="$(dirname "$(realpath $0)")/../opt/drl"
    if ! [[ $DRL ]]; then
      >&2 echo "Error determining location of system DRL install!"
      exit 1
    else
      >&2 echo "Located system DRL at $DRL"
      >&2 echo "Setting up user files..."
    fi

    DRL_HOME="''${DRL_HOME:-$HOME/.config/drl}"

    mkdir -p "$DRL_HOME"/{backup,config,modules,mortem,screenshot}
    cd "$DRL_HOME"
    ln -sf -t . "$DRL"/*.wad "$DRL"/*.txt "$DRL"/drl "$DRL"/drl_* "$DRL"/{mp3,wavhq}
    cp -n -t . "$DRL"/*.lua
    chmod u+w *.lua
    echo "Setup complete, launching DRL!"

    if [[ $DISPLAY ]]; then
      exec ./drl "$@"
    else
      exec ./drl -console "$@"
    fi
  '';
in stdenv.mkDerivation {
  pname = "drl";
  version = "0.9.9.8";

  inherit src;

  nativeBuildInputs = [ fpc git lua5_1 ];
  buildInputs = [ ncurses xorg.libX11 ];

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  postUnpack = ''
    cd source

    # Build process needs tmp/ and doesn't create it automatically.
    mkdir -p tmp

    # Linker wants liblua5.1, not liblua
    ln -s ${lua5_1}/lib/liblua.a liblua5.1.a

    # Bring in the media files from the binary release.
    rm -rf bin/mp3 bin/wavhq
    ln -s ${release}/wavhq ${release}/mp3 bin/
    cp ${release}/*.wad bin/

    cd ..
  '';

  buildPhase = ''
    # Disable makewad because we're just using the wad from the binary release
    # anyways, and it makes cross-compiling a pain.
    sed -Ei '/execute_in_dir.*makewad/ d' makefile.lua
    export FPCVALKYRIE_ROOT=${fpcvalkyrie}/
    lua makefile.lua hq
  '';

  patchPhase = ''
  '';

  # runtime dependencies
  libPath = lib.makeLibraryPath runtimeDeps;
  installPhase = ''
    mkdir -p "$out/opt/drl" "$out/bin/"
    tar xf drl-linux-0998.tar.gz -C "$out/opt/drl" --strip-components 1

    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      --set-rpath "$libPath" \
      "$out/opt/drl/drl"

    cp -p ${launcher} "$out/bin/drl"
  '';
}
