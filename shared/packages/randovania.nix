{ stdenv
, lib
, autoPatchelfHook
, fetchurl
, libdrm
, libGL
, libxcrypt-legacy
, libxkbcommon
, lttng-ust_2_12
, SDL2
, qt6
, xorg
}:

stdenv.mkDerivation rec {
  pname = "randovania";
  version = "8.8.0";

  src = fetchurl {
    url = "https://github.com/randovania/${pname}/releases/download/v${version}/${pname}-${version}-linux.tar.gz";
    hash = "sha256-CRr9l3UK0M+FbMKp6T3QAnNCleJc76ewSIlEgBaEYhw=";
  };

  nativeBuildInputs = [ autoPatchelfHook qt6.wrapQtAppsHook ];
  buildInputs = [
    libdrm
    libGL
    libxcrypt-legacy
    libxkbcommon
    lttng-ust_2_12
    qt6.qtbase
    qt6.qtwayland
    SDL2
    xorg.libxcb
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    cp -r . $out/opt/randovania
    # The version of libxkbcommon it ships with segfaults under wayland, so use
    # the system one instead.
    rm $out/opt/randovania/_internal/libxkbcommon.*

    makeQtWrapper $out/opt/randovania/randovania $out/bin/randovania \
      --prefix QT_XKB_CONFIG_ROOT ":" "${xorg.xkeyboardconfig}/share/X11/xkb"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A randomizer platform for multiple games";
    homepage = "https://randovania.org/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ toxicfrog ];
  };
}
