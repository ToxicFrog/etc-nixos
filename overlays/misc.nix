self: super:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  libmysofa = super.libmysofa.overrideAttrs (oldAttrs: {
    cmakeFlags = [ "-DBUILD_TESTS=OFF" "-DCODE_COVERAGE=OFF" ];
  });
  fuse = super.fuse.overrideAttrs (oldAttrs: {
    # Very hacky workaround to make sure that mount.fuse can search PATH:
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i \
        -e '/execl/i setenv("PATH", "/run/current-system/sw/bin", 1);' \
        util/mount.fuse.c
    '';
  });
#  bitlbee = super.bitlbee.overrideAttrs (oldAttrs: {
#    name = "${oldAttrs.name}+purple";
#    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [self.pidgin];
#    configureFlags = oldAttrs.configureFlags ++ ["--purple=1" "--jabber=1"];
#  });
  crossfire-server-latest = super.crossfire-server-latest.overrideAttrs (oldAttrs: {
    # Reset maps every 8h rather than every 2h.
    postConfigure = ''
      sed -Ei 's,^#define MAP_MAXRESET.*,#define MAP_MAXRESET 28800,' include/config.h
      sed -Ei 's,^#define MAP_DEFAULTRESET.*,#define MAP_DEFAULTRESET 28800,' include/config.h
    '';
  });
  munin = super.munin.overrideAttrs (oldAttrs: {
    # HACK HACK HACK
    # perl -T breaks makeWrapper
    postFixup = ''
      echo "Removing references to /usr/{bin,sbin}/ from munin plugins..."
      find "$out/lib/plugins" -type f -print0 | xargs -0 -L1 \
          sed -i -e "s|/usr/bin/||g" -e "s|/usr/sbin/||g" -e "s|\<bc\>|${self.bc}/bin/bc|g"
      if test -e $out/nix-support/propagated-build-inputs; then
          ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
      fi

      sed -E -i "s/perl -T/perl/" "$out"/www/cgi/*

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
