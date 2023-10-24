{ stdenv, makeWrapper, gradle_6, jre, ffmpeg }:

stdenv.mkDerivation rec {
  name = "crossfire-jxclient";
  version = "2023-06-23";

  src = builtins.fetchGit {
    url = "https://git.code.sf.net/p/crossfire/jxclient";
    ref = "master";
    rev = "fddc21e368b2f998d968169dc72d4b7ea747f8b0";
    submodules = true;
    shallow = true;
  };

  nativeBuildInputs = [ gradle_6 makeWrapper ffmpeg ];

  buildPhase = ''
    gradle :createJar
  '';

  installPhase = ''
    mkdir -pv $out/share/java $out/bin
    cp jxclient.jar $out/share/java/jxclient.jar

    makeWrapper ${jre}/bin/java $out/bin/crossfire-jxclient \
      --add-flags "-jar $out/share/java/jxclient.jar" \
      --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
      --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
