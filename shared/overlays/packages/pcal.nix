{lib, stdenv, fetchurl, groff}:

stdenv.mkDerivation rec {
  pname = "pcal";
  version = "4.11.0";

  src = fetchurl {
    url = "mirror://sourceforge/project/${pname}/${pname}/${pname}-${version}/${pname}-${version}.tgz";
    hash = "sha256-hAYZDnkSCCcZJitxtj7jGpj6zkmqUil9uWzAyXD40gc=";
  };

  nativeBuildInputs = [ groff ];
  makeFlags = [
    "CC=gcc"
    "PACK=gzip"
    "DESTDIR=$(out)"
    "BINDIR=bin"
    "MANDIR=share/man/man1"
    "CATDIR=share/man/cat1"
  ];

  meta = {
    description = "PostScript monthly and yearly calendars";
    license = lib.licenses.gpl2;
    maintainers = [lib.maintainers.toxicfrog];
    platforms = lib.platforms.linux;
    downloadPage = "https://sourceforge.net/projects/pcal/files/pcal";
  };
}
