self: super:

{
  calibre = super.calibre.overrideAttrs (oldAttrs: {
    name = "calibre-3.12.0";
    version = "3.12.0";
    src = self.fetchurl {
      url = "https://download.calibre-ebook.com/3.12.0/calibre-3.12.0.tar.xz";
      sha256 = "0l7r5ny9a36yg22fqzz3as6wh1xqpa3hrlx2gy25yp649sbkd9vq";
    };
  });
  fuse = super.fuse.overrideAttrs (oldAttrs: {
    # Very hacky workaround to make sure that mount.fuse can search PATH:
    postPatch = (oldAttrs.postPatch or "") + ''
      sed -i \
        -e '/execl/i setenv("PATH", "/run/current-system/sw/bin", 1);' \
        util/mount.fuse.c
    '';
  });
  bup = super.bup.overrideAttrs (oldAttrs: {
    name = "bup-0.29.1-ancilla-1";
    src = self.fetchFromGitHub {
      repo = "bup";
      owner = "toxicfrog";
      rev = "master";
      sha256 = "1g8jb9nkqh9bc4c3akhg9pfih14j957j2aqr0lsxy7lsc3q2y65b";
    };
  });
  bitlbee = super.bitlbee.overrideAttrs (oldAttrs: {
    name = "${oldAttrs.name}+purple";
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [self.pidgin];
    configureFlags = oldAttrs.configureFlags ++ ["--purple=1" "--jabber=1"];
  });
  purple-hangouts = super.purple-hangouts.overrideAttrs (oldAttrs: {
    name = "purple-hangouts-hg-2017-10-03";
    version = "2017-10-03";
    src = self.fetchhg {
      url = "https://bitbucket.org/EionRobb/purple-hangouts/";
      rev = "5e76979";
      sha256 = "0cs7dcd44lkc2anradyddjvmfvnl46ixw4idaf1m9fd7j35mg7b1";
    };
    patches = [ ./hangouts-me.diff ];
  });
}
