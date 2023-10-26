{ stdenv, makeWrapper, gradle_6, jre }:

stdenv.mkDerivation rec {
  name = "crossfire-editor";
  version = "2023-10-13";

  src = builtins.fetchGit {
    url = "https://git.code.sf.net/p/gridarta/gridarta";
    ref = "master";
    rev = "6928c5eb7c894d7e97a20af5495d3fb39d66a516";
    submodules = true;
    shallow = true;
  };

  nativeBuildInputs = [ gradle_6 makeWrapper ];

  patches = [ ./crossfire-editor.patch ];

  buildPhase = ''
    gradle :src:crossfire:createEditorJar
  '';

  installPhase = ''
    mkdir -pv $out/share/java $out/bin
    cp src/crossfire/build/libs/CrossfireEditor.jar $out/share/java/crossfire-editor.jar

    makeWrapper ${jre}/bin/java $out/bin/crossfire-editor \
      --add-flags "-jar $out/share/java/crossfire-editor.jar" \
      --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
      --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
