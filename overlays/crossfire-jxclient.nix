let pkgs = import <nixpkgs> {};
in
{ stdenv ? pkgs.stdenv
, fetchurl ? pkgs.fetchurl
, makeWrapper ? pkgs.makeWrapper
, jre ? pkgs.jre
}:

stdenv.mkDerivation rec {
  name = "crossfire-jxclient";
  version = "2023-05-05";

  # Simply fetch the JAR file of GINsim.
  src = fetchurl {
    # https://sourceforge.net/projects/crossfire/files/gridarta-crossfire/CrossfireEditor.jar/download
    url = "https://sourceforge.net/projects/crossfire/files/jxclient/jxclient.jar/download";
    sha256 = "sha256-Y5f9aIG6Uh+Zqx1mqshjt3K71Am1nKUhbf4gUsmxvVc=";
  };
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -pv $out/share/java $out/bin
    cp ${src} $out/share/java/${name}-${version}.jar

    makeWrapper ${jre}/bin/java $out/bin/crossfire-jxclient \
      --add-flags "-jar $out/share/java/${name}-${version}.jar" \
      --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
      --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
