{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  autoreconfHook,
  cmake,
  fetchFromGitHub,
  curl,
  glib,
  openssl,
  pkg-config,
  python3,
  SDL2,
  SDL2_mixer,
  SDL2_net,
  xorg,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "apdoom";
  version = "1.2.0-pre1";

  src = fetchurl {
    url = "https://github.com/Daivuk/${pname}/releases/download/${version}/APDOOM-1_2_0pre-Ubuntu2204.tar.gz";
    hash = "sha256-nh0H4NMcnASGBCbbqQyrhrgL/pXAbSUMluUhHBziFCk=";
  };
  sourceRoot = ".";

  # cmake fails to find SDL2::main for some reason, so just fetch the binary
  # for now
  # src = fetchFromGitHub {
  #   owner = "Daivuk";
  #   repo = pname;
  #   rev = version;
  #   fetchSubmodules = true;
  #   hash = "sha256-C8IcdWIEsfUq5GxHumr2cfa1JC8JKb0Ey50iGx28rRw=";
  # };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    curl
    glib
    openssl
    (SDL2.override { withStatic = true; })
    SDL2_mixer
    SDL2_net
    xorg.libXext
    zlib
  ];

  # FIXME: apdoom really wants to read and write stuff in its working directory,
  # so we need a wrapper similar to what doomrl does here
  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    cp -r . $out/opt/apdoom

    ln -s $out/opt/apdoom/crispy-apdoom $out/bin/apdoom
    ln -s $out/opt/apdoom/crispy-apheretic $out/bin/apheretic
    ln -s $out/opt/apdoom/crispy-setup $out/bin/apsetup

    runHook postInstall
  '';


  meta = {
    homepage = "https://github.com/Daivuk/apdoom";
    description = "Limit-removing Doom source port for multiworld randomizer games";
    longDescription = ''
      Archipelago Doom is a fork of Crispy Doom with added features to support the
      Archipelago randomizer co-op system.
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ toxicfrog ];
  };
}
