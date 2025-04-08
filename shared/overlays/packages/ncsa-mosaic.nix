{ stdenv
, lib
, fetchFromGitHub
, gnumake
, gnused
, gcc
, libjpeg
, libpng
, motif
, xorg

, automake
, fuse
, ffmpeg
, pkg-config
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

stdenv.mkDerivation rec {
  pname = "xmosaic";
  version = "2.7";

  src = fetchFromGitHub {
    owner = "alandipert";
    repo = "ncsa-mosaic";
    rev = "2e9a6053fa39487c0f427dc423bedd3747724bbb";
    hash = "sha256-imcn4zz5Jp+5b155Rd6XKgumif/0yUGT3vSf23x2arw=";
  };

  nativeBuildInputs = [ gnumake gnused gcc ];
  buildInputs = [ libjpeg libpng motif xorg.libX11 xorg.libXext xorg.libXmu xorg.libXpm xorg.xorgproto ];

  postPatch = ''
    sed -Ei '
      s/old, b/old, "%s", b/
      s/new, b/new, "%s", b/
    ' src/newsrc.c
    sed -Ei '
      s,^struct time,static struct time,
    ' src/xpmread.c libhtmlw/HTMLparse.c
    sed -Ei '
      s,^int ,extern int ,
    ' src/kcms.h
    echo ' int KCMS_Enabled, KCMS_Return_Format;' >> src/kcms.c
  '';

  # CFLAGS = [ "-Wno-error" ];
  makeFlags = [
    "DEV_ARCH=linux" # TODO: support linux-static if stdenv.hostPlatform.isStatic
    # Doesn't build under modern gcc unless you turn off a bunch of safety railings
    "customflags=-Wno-error"
  ];

  installPhase = ''
    mkdir -p $out/bin/
    cp src/Mosaic $out/bin/xmosaic
  '';

  meta = with lib; {
    description = "One of the first graphical web browsers";
    homepage = "https://www.ncsa.illinois.edu/research/project-highlights/ncsa-mosaic/";
    license = "NCSA";
    platforms = platforms.unix;
    # maintainers = with maintainers; [ ToxicFrog ];
  };
}
