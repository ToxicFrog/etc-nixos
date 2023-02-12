self: super:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  # fuse = super.fuse.overrideAttrs (oldAttrs: {
  #   # Very hacky workaround to make sure that mount.fuse can search PATH:
  #   postPatch = (oldAttrs.postPatch or "") + ''
  #     sed -i \
  #       -e '/execl/i setenv("PATH", "/run/current-system/sw/bin", 1);' \
  #       util/mount.fuse.c
  #   '';
  # });
  crossfire-server = super.crossfire-server.overrideAttrs (oldAttrs: {
    # Reset maps every 8h rather than every 2h.
    postConfigure = ''
      sed -Ei 's,^#define MAP_MAXRESET.*,#define MAP_MAXRESET 28800,' include/config.h
      sed -Ei 's,^#define MAP_DEFAULTRESET.*,#define MAP_DEFAULTRESET 28800,' include/config.h
    '';
  });
  factor-lang = super.factor-lang.overrideAttrs (old: {
    version = "0.99";
    src = super.fetchFromGitHub {
      owner = "factor"; repo = "factor";
      rev = "d5a2d1cf1b98b9ded7fa7330cdc0e58dd01551c1";
      sha256 = "JDIr20fiGnsMwG1rdudTHO5TTAe5ZZmoJL4TRHv5geE=";
    };
    bootstrap = super.fetchurl {
      url = "https://downloads.factorcode.org/images/master/boot.unix-x86.64.image";
      sha256 = "2+dway20pYoHgTTNGASV5R6VtyPCOhj0ntm4wyuSdlA=";
    };
    preBuild = ''
      cp $bootstrap boot.unix-x86.64.image
    '';
    patches = [];
  });
  ffmpeg-full = super.ffmpeg-full.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--disable-libmodplug"
      "--enable-libopenmpt"
      "--enable-libgme"
    ];
    buildInputs = old.buildInputs ++ [
      self.libopenmpt self.libgme
    ];
  });
  munin = super.munin.overrideAttrs (oldAttrs: {
    # HACK HACK HACK
    # perl -T breaks makeWrapper
    postFixup = ''
      echo "Removing references to /usr/{bin,sbin}/ from munin plugins..."
      find "$out/lib/plugins" -type f -print0 | xargs -0 -L1 \
          ${self.gnused}/bin/sed -i -e "s|/usr/bin/||g" -e "s|/usr/sbin/||g" -e "s|\<bc\>|${self.bc}/bin/bc|g"
      if test -e $out/nix-support/propagated-build-inputs; then
          ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
      fi

      ${self.gnused}/bin/sed -E -i "s/perl -T/perl/" "$out"/www/cgi/*

      for file in "$out"/bin/munindoc "$out"/sbin/munin-* "$out"/lib/munin-* "$out"/www/cgi/*; do
          # don't wrap .jar files
          case "$file" in
              *.jar) continue;;
          esac
          wrapProgram "$file" \
            --set PERL5LIB "$out/${self.perlPackages.perl.libPrefix}:${with self.perlPackages; makePerlPath [
                  LogLog4perl IOSocketInet6 Socket6 URI DBFile DateManip
                  HTMLTemplate FileCopyRecursive FCGI NetCIDR NetSNMP NetServer
                  ListMoreUtils DBDPg LWP self.rrdtool CGIFast CGI
                  ]}"
      done
    '';
  });
}
