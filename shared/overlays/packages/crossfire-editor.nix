{ stdenv, makeWrapper, gradle_7, jre8, jdk8 }:

stdenv.mkDerivation rec {
  name = "crossfire-editor";
  version = "2024-09-08";

  src = builtins.fetchGit {
    url = "https://git.code.sf.net/p/gridarta/gridarta";
    ref = "master";
    rev = "2e407c46a5b3588557200b203898cbcb7a019af3";
    submodules = true;
    shallow = true;
  };

  nativeBuildInputs = [ gradle_7 makeWrapper ];

  patches = [ ./crossfire-editor.patch ];
  # postPatch = ''
  #   sed -E -i 's,configurations.runtime,configurations.runtimeOnly,' \
  #     src/*/build.gradle
  # '';

  buildPhase = ''
    export JAVA_HOME=${jdk8}
    sh ./gradlew :src:crossfire:createEditorJar
    # gradle :src:crossfire:createEditorJar
  '';

  installPhase = ''
    mkdir -pv $out/share/java $out/bin
    cp src/crossfire/build/libs/CrossfireEditor.jar $out/share/java/crossfire-editor.jar

    makeWrapper ${jre8}/bin/java $out/bin/crossfire-editor \
      --add-flags "-jar $out/share/java/crossfire-editor.jar" \
      --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
      --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
}
