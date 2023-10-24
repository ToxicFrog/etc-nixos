final: prev: {
  munin = prev.munin.overrideAttrs (oldAttrs: {
    # HACK HACK HACK
    # perl -T breaks makeWrapper
    # TODO: see if this is still needed!
    postFixup = ''
      echo "Removing references to /usr/{bin,sbin}/ from munin plugins..."
      find "$out/lib/plugins" -type f -print0 | xargs -0 -L1 \
          ${final.gnused}/bin/sed -i -e "s|/usr/bin/||g" -e "s|/usr/sbin/||g" -e "s|\<bc\>|${final.bc}/bin/bc|g"
      if test -e $out/nix-support/propagated-build-inputs; then
          ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
      fi

      ${final.gnused}/bin/sed -E -i "s/perl -T/perl/" "$out"/www/cgi/*

      for file in "$out"/bin/munindoc "$out"/sbin/munin-* "$out"/lib/munin-* "$out"/www/cgi/*; do
          # don't wrap .jar files
          case "$file" in
              *.jar) continue;;
          esac
          wrapProgram "$file" \
            --set PERL5LIB "$out/${final.perlPackages.perl.libPrefix}:${with final.perlPackages; makePerlPath [
                  LogLog4perl IOSocketInet6 Socket6 URI DBFile DateManip
                  HTMLTemplate FileCopyRecursive FCGI NetCIDR NetSNMP NetServer
                  ListMoreUtils DBDPg LWP final.rrdtool CGIFast CGI
                  ]}"
      done
    '';
  });
}
