inputs: self: super:

rec {
  crossfire-server =
    (super.crossfire-server.override { arch = crossfire-arch; maps = crossfire-maps; })
    .overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = inputs.crossfire-server;
    NIX_CFLAGS_COMPILE = "-g -O0";
    NIX_CXXFLAGS_COMPILE = "-g -O0";
    preConfigure = ''
      rm -f lib/maps lib/arch
      ln -sf ${crossfire-arch} lib/arch
      ln -sf ${crossfire-maps} lib/maps
      sh autogen.sh
    '';
    # Reset maps every week rather than every 2h.
    postConfigure = ''
      sed -Ei 's,^#define MAP_MAXRESET .*,#define MAP_MAXRESET 604800,' include/config.h
      sed -Ei 's,^#define MAP_DEFAULTRESET .*,#define MAP_DEFAULTRESET 604800,' include/config.h
      sed -Ei 's,^#define TMPDIR .*,#define TMPDIR "tmp",' include/config.h
      rm -f lib/.collect-stamp lib/crossfire.arc
    '';
    # Point maps at /srv/crossfire so we can edit them live.
    preFixup = ''
      rm -f $out/share/crossfire/maps
      ln -s /srv/crossfire/maps $out/share/crossfire/maps
    '';
    hardeningDisable = [ "all" ];
  });
  crossfire-arch = super.crossfire-arch.overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = inputs.crossfire-arch;
  });
  crossfire-maps = super.crossfire-maps.overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = inputs.crossfire-maps;
  });
  crossfire-jxclient = super.callPackage ../packages/crossfire-jxclient.nix {};
  crossfire-editor = super.callPackage ../packages/crossfire-editor.nix {};
}
