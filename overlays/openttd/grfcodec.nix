{ stdenv, fetchFromGitHub, boost }:

stdenv.mkDerivation rec {
  pname = "openttd-grfcodec";
  version = "6.0.6";

  src = fetchFromGitHub {
    owner = "OpenTTD";
    repo = "grfcodec";
    rev = version;
    sha256 = "15dl3v9n02j0zrlxazkv90zsp9z14swqz4c0q36b5hsfcdxjdhnl";
  };

  # prePatch = ''
  #   sed -E -i 's,Image.VERSION,Image.PILLOW_VERSION,g' nml/version_info.py
  # '';

  buildInputs = [boost];

  installPhase = ''
    mkdir -p $out/bin
    cp -a grfcodec grfid grfstrip nforenum $out/bin/
  '';

  meta = with stdenv.lib; {
    description = "Low-level (dis)assembler and linter for OpenTTD GRF files";
    homepage    = "http://openttd.org/";
    license     = licenses.gpl2;
    maintainers = with maintainers; [ ToxicFrog ];
  };
}
