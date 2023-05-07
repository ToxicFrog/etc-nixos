self: super:

rec {
  crossfire-server =
    (super.crossfire-server.override { arch = crossfire-arch; maps = crossfire-maps; })
    .overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = /home/rebecca/devel/crossfire-server;
    preConfigure = ''
      ln -sf ${crossfire-arch} lib/arch
      ln -sf ${crossfire-maps} lib/maps
      sh autogen.sh
    '';
    # Reset maps every week rather than every 2h.
    postConfigure = ''
      sed -Ei 's,^#define MAP_MAXRESET .*,#define MAP_MAXRESET 604800,' include/config.h
      sed -Ei 's,^#define MAP_DEFAULTRESET .*,#define MAP_DEFAULTRESET 604800,' include/config.h
      sed -Ei 's,^#define TMPDIR .*,#define TMPDIR "tmp",' include/config.h
    '';
  });
  crossfire-arch = super.crossfire-arch.overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = builtins.fetchGit "/home/rebecca/devel/crossfire-arch";
    #src = /home/rebecca/devel/crossfire-arch;
  });
  crossfire-maps = super.crossfire-maps.overrideAttrs (oldAttrs: {
    version = "HEAD";
    src = builtins.fetchGit "/home/rebecca/src/crossfire-maps";
  });
  crossfire-jxclient = super.callPackage ./crossfire-jxclient.nix {};
  crossfire-editor = super.callPackage ./crossfire-editor.nix {};
}
