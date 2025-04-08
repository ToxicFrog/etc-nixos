{ stdenv
, lib
, fetchFromGitHub
, gtk2-x11
, makeWrapper
, msbuild
, libGL
, libpng
, libX11
, mono
, zdbsp
}:

stdenv.mkDerivation rec {
  pname = "UltimateDoomBuilder";
  version = "3.0.0.3274";
  src = fetchFromGitHub {
    owner = "UltimateDoomBuilder";
    repo = pname;
    rev = "cff1d000b7bd51380d676e13a9319ae147a4a357";
    hash = "sha256-uB9AfYidn7pgzB4cGP5hTPMVSTEK/G7UTIqgC7ZW5P4=";
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
    # substituteInPlace $out/opt/UltimateDoomBuilder/Compilers/BCC/bcc.cfg --replace bcc.exe ${zt-bcc}/bin/zt-bcc
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/opt

    cp -r Build $out/opt/UltimateDoomBuilder

    substituteInPlace $out/opt/UltimateDoomBuilder/builder --replace mono ${mono}/bin/mono
    substituteInPlace $out/opt/UltimateDoomBuilder/builder --replace Builder.exe $out/opt/UltimateDoomBuilder/Builder.exe
    substituteInPlace $out/opt/UltimateDoomBuilder/Compilers/Nodebuilders/zdbsp.cfg --replace zdbsp.exe ${zdbsp}/bin/zdbsp

    wrapProgram $out/opt/UltimateDoomBuilder/builder \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ gtk2-x11 libGL libpng libX11 ]}"

    ln -s $out/opt/UltimateDoomBuilder/builder $out/bin/udb
  '';
}
