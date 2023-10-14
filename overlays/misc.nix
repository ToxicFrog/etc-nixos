self: super:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in rec {
  # fuse = super.fuse.overrideAttrs (oldAttrs: {
  #   # Very hacky workaround to make sure that mount.fuse can search PATH:
  #   postPatch = (oldAttrs.postPatch or "") + ''
  #     sed -i \
  #       -e '/execl/i setenv("PATH", "/run/current-system/sw/bin", 1);' \
  #       util/mount.fuse.c
  #   '';
  # });
  factor-lang = super.factor-lang.overrideAttrs (old: {
    version = "0.99";
    src = super.fetchFromGitHub {
      owner = "factor"; repo = "factor";
      rev = "e70d0fd819eb8b9d5a15213428df22a73ce6b210";
      sha256 = "sha256-cQl1jxhiNt9apAQNq1ICWkFlfr1MiRVmAPEZHdJZ6/o=";
    };
    bootstrap = super.fetchurl {
      url = "https://downloads.factorcode.org/images/master/boot.unix-x86.64.image";
      sha256 = "sha256-jVy9ylkDPVkl51RraNSF9/PIpSSCVQh1kDgybHgLGGU=";
    };
    preBuild = ''
      cp $bootstrap boot.unix-x86.64.image
    '';
    patches = [];
  });
  libgme-vgz = super.game-music-emu.overrideAttrs (old: {
    cmakeFlags = [ "-DENABLE_UBSAN=OFF" ];
    buildInputs = [ self.zlib ];
  });
  ffmpeg-vgz = (super.ffmpeg-full.overrideAttrs { pname = "ffmpeg-vgz"; })
    .override { game-music-emu = self.libgme-vgz; };
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
