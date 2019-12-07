self: super:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  fuse = super.fuse.overrideAttrs (oldAttrs: {
    # Very hacky workaround to make sure that mount.fuse can search PATH:
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i \
        -e '/execl/i setenv("PATH", "/run/current-system/sw/bin", 1);' \
        util/mount.fuse.c
    '';
  });
  bitlbee = super.bitlbee.overrideAttrs (oldAttrs: {
    name = "${oldAttrs.name}+purple";
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [self.pidgin];
    configureFlags = oldAttrs.configureFlags ++ ["--purple=1" "--jabber=1"];
  });
  purple-hangouts = unstable.purple-hangouts;
  # TODO build airsonic from source so that this actually works
  # airsonic = super.airsonic.overrideAttrs (oldAttrs: {
  #   patches = [
  #     ./airsonic-podcast-order.patch
  #   ];
  # });
  crossfire-server-latest = super.crossfire-server-latest.overrideAttrs (oldAttrs: {
    # Reset maps every 8h rather than every 2h.
    postConfigure = ''
      sed -Ei 's,^#define MAP_MAXRESET.*,#define MAP_MAXRESET 28800,' include/config.h
      sed -Ei 's,^#define MAP_DEFAULTRESET.*,#define MAP_DEFAULTRESET 28800,' include/config.h
    '';
  });
  # perl 5.30 breaks plugins
  munin = super.munin.override {
    perlPackages = super.perl528Packages;
    rrdtool = super.rrdtool.override {
      perl = super.perl528Packages.perl;
    };
  };
}
