final: prev: {
  munin = prev.munin.overrideAttrs (old: {
    # HACK HACK HACK
    # perl -T breaks makeWrapper --set PERL5LIB; see https://github.com/NixOS/nixpkgs/issues/263396
    postFixup = ''
      ${final.gnused}/bin/sed -E -i "s/perl -T/perl/" "$out"/www/cgi/*
    '' + old.postFixup;
  });
}
