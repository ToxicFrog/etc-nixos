{ stdenv
, lib
, fetchFromGitHub
# , cmake
, autoconf
, automake
, fuse
, ffmpeg
, pkg-config
, gnused
, sqlite
, libcue
, libchardet
, libdvdread
, libdvdnav
, libbluray
, asciidoc-full
, chromaprint
, w3m
, xxd
}:

let
  version = "2.15-devel";
in stdenv.mkDerivation rec {
  pname = "ffmpegfs";
  inherit version;

  src = fetchFromGitHub {
    owner = "nschlia";
    repo = "ffmpegfs";
    # rev = "v${version}";
    # hash = "sha256-HKqrrcZ9hldwS8NjYLJLw1dgbzl0N5U/U5UaJ3VedBs=";
    rev = "8d165553be9e11139699aeef74bc8fb49e5cea8b";
    hash = "sha256-AEM2+cRV4iLlN1eS+ZV6szoBUS72yuHdQB4cwUBI3M8=";
  };

  nativeBuildInputs = [
    autoconf automake pkg-config
    asciidoc-full w3m gnused xxd
  ];
  buildInputs = [ fuse ffmpeg sqlite libcue libchardet libdvdread libbluray chromaprint libdvdnav ];

  postPatch = ''
    ./autogen.sh
  '';

  # makeFlags = [ "VERBOSE=1" ];
  # enableParallelBuilding = false;

  meta = with lib; {
    description = "A FUSE pseudo-filesystem that transcodes media files on access";
    homepage = https://nschlia.github.io/ffmpegfs/;
    license = "GPLv3";
    platforms = platforms.unix;
    # maintainers = with maintainers; [ ToxicFrog ];
  };
}
