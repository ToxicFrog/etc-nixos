{ lib, stdenv, buildGoModule, fetchFromGitHub
, nixosTests
, pkg-config, taglib, zlib
, transcodingSupport ? true, ffmpeg
, mpv }:

buildGoModule rec {
  pname = "gonic";
  version = "0.16.0-rc1";
  src = fetchFromGitHub {
    owner = "sentriz";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-Tb6hMiHGbbvAKuVZ7/GBXPVu5dLAp+ePfYg4e88FzyQ=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ taglib zlib ];
  vendorHash = "sha256-rCVrqD4B6eWew1kk+JXve/ns+FMZdCVIMSbnsRz+uo0=";

  postPatch = lib.optionalString transcodingSupport ''
    substituteInPlace \
      transcode/transcode.go \
      --replace \
        '`ffmpeg' \
        '`${lib.getBin ffmpeg}/bin/ffmpeg'
  '' + ''
    substituteInPlace \
      jukebox/jukebox.go \
      --replace \
        '"mpv"' \
        '"${lib.getBin mpv}/bin/mpv"'
  '';

  passthru = {
    tests.gonic = nixosTests.gonic;
  };

  meta = {
    homepage = "https://github.com/sentriz/gonic";
    description = "Music streaming server / subsonic server API implementation";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
  };
}
