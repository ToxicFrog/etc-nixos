{ stdenv, makeWrapper, gradle, jre, ffmpeg }:

stdenv.mkDerivation rec {
  name = "crossfire-jxclient";
  version = "2024-12-25";

  src = builtins.fetchGit {
    url = "https://git.code.sf.net/p/crossfire/jxclient";
    ref = "master";
    rev = "6c2f7d344ffaf7241d394810737408fa608f495b";
    submodules = true;
    shallow = true;
  };

  nativeBuildInputs = [ jre gradle makeWrapper ffmpeg ];

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
