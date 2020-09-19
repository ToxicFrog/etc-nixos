{ stdenv, fetchsvn, version, rev, sha256 }:

stdenv.mkDerivation rec {
  version = "r${toString rev}";
  name = "crossfire-arch-${version}";

  # src = fetchsvn {
  #   url = "http://svn.code.sf.net/p/crossfire/code/arch/trunk/";
  #   sha256 = sha256;
  #   rev = rev;
  # };
  src = builtins.path {
    path = /home/rebecca/devel/crossfire-arch;
    name = "crossfire-server-devel";
    filter = (path: type: baseNameOf path != ".git");
  };

  hydraPlatforms = [];
  phases = ["unpackPhase" "installPhase"];
  installPhase = ''
    mkdir -p "$out"
    cp -a . "$out/"
  '';

  meta = with stdenv.lib; {
    description = "Archetype data for the Crossfire free MMORPG";
    homepage = "http://crossfire.real-time.com/";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ToxicFrog ];
  };
}
