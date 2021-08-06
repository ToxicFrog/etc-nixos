{ stdenv, lib, fetchsvn,
  cmake, pkg-config, perl, vala,
  gtk2, pcre, zlib, libpng, fribidi, harfbuzzFull, xorg, utillinuxMinimal, curl,
  SDL, SDL_image, SDL_mixer, libselinux, libsepol,
  version, rev, sha256 }:

stdenv.mkDerivation rec {
  version = "r${toString rev}";
  name = "crossfire-client-${version}";

  src = fetchsvn {
    url = "http://svn.code.sf.net/p/crossfire/code/client/trunk/";
    sha256 = sha256;
    rev = rev;
  };

  nativeBuildInputs = [cmake pkg-config perl vala];
  buildInputs = [gtk2 pcre zlib libpng fribidi harfbuzzFull xorg.libpthreadstubs
    xorg.libXdmcp utillinuxMinimal curl SDL SDL_image SDL_mixer libselinux libsepol];
  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "GTKv2 client for the Crossfire free MMORPG";
    homepage = "http://crossfire.real-time.com/";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ToxicFrog ];
  };
}
