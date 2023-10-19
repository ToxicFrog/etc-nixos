let pkgs = import <nixpkgs> {};
in
{ stdenv ? pkgs.stdenv
, fetchurl ? pkgs.fetchurl
, makeWrapper ? pkgs.makeWrapper
, jre ? pkgs.jre
}:

stdenv.mkDerivation rec {
  name = "crossfire-editor";
  version = "2023-10-09";

  src = fetchurl {
    url = "https://sourceforge.net/projects/crossfire/files/gridarta-crossfire/CrossfireEditor.jar/download";
    sha256 = "sha256-0ZnX4H5Et9c7UQe/QSTwLq7P8dJf519ZTcKDxBaeip4=";
  };
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -pv $out/share/java $out/bin
    cp ${src} $out/share/java/${name}-${version}.jar

    makeWrapper ${jre}/bin/java $out/bin/crossfire-editor \
      --add-flags "-jar $out/share/java/${name}-${version}.jar" \
      --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
      --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
