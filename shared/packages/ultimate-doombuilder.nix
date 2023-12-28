{ stdenv
, fetchFromGitHub
, gtk2-x11
, makeWrapper
, msbuild
, libGL
, libpng
, libX11
, mono
}:

stdenv.mkDerivation rec {
  pname = "UltimateDoomBuilder";
  version = "3.0.0.3274";
  src = fetchFromGitHub {
    owner = "jewalky";
    repo = pname;
    rev = "eb974fcaf08d54c20ddc697d04f4eca84e805016";
    hash = "sha256-vl3w1q5ssOPpPxkwmq4hKgJkA7oe8W53IYXrN4ezX7c=";
  };
  nativeBuildInputs = [
    msbuild makeWrapper
  ];
  buildInputs = [
    gtk2-x11
    libGL
    libpng
    libX11
    mono
  ];
  buildPhase = ''
    runHook preBuild

    # Won't compile without windows codepage identifier for UTF-8

    msbuild /nologo /verbosity:minimal -p:Configuration=Release /p:codepage=65001 ./BuilderMono.sln
    cp builder.sh Build/builder
    chmod +x Build/builder
    g++ -std=c++14 -O2 --shared -g3 -o Build/libBuilderNative.so -fPIC -I Source/Native Source/Native/*.cpp Source/Native/OpenGL/*.cpp Source/Native/OpenGL/gl_load/*.c -lX11 -ldl
    runHook postBuild
  '';
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/opt
    cp -r Build $out/opt/UltimateDoomBuilder
    substituteInPlace $out/opt/UltimateDoomBuilder/builder --replace mono ${mono}/bin/mono
    substituteInPlace $out/opt/UltimateDoomBuilder/builder --replace Builder.exe $out/opt/UltimateDoomBuilder/Builder.exe
    ln -sf $out/opt/UltimateDoomBuilder/builder $out/bin/udb
  '';
}
