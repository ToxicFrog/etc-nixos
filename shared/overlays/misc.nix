self: super:

{
  # Simple packages
  doomrl = super.callPackage ./packages/doomrl.nix {};
  drl = super.callPackage ./packages/drl.nix {};
  etcd = super.etcd_3_4; # TODO: try upgrading to latest stable (3.5)
  # golly = super.callPackage ./packages/golly.nix {};
  matrix2051 = super.callPackage ./packages/matrix2051.nix {};
  pcal = super.callPackage ./packages/pcal.nix {};
  # pgvecto-rs = super.callPackage ./packages/pgvecto-rs.nix {};
  randovania = super.callPackage ./packages/randovania.nix {};
  sigal = super.callPackage ./packages/sigal.nix {};
  slashem9 = super.callPackage ./packages/slashem9/default.nix {};
  udb-editor = super.callPackage ./packages/ultimate-doombuilder.nix {};

  # Actual overrides
  dtrx = (super.dtrx.overrideAttrs (old: {
    version = "8.5.3+git";

    src = super.fetchFromGitHub {
      owner = "dtrx-py";
      repo = "dtrx";
      rev = "fb61df037f5303e5e348c16e3afbc103a8568f35";
      sha256 = "sha256-2O9pVgR4luGZmJWlMA3kwyT1hgnSqb/O50vcDksxTOo=";
    };
  }));
  # TODO: add an overlay for calibre that adds the libcrypto dependency that ACSM import needs
  ffmpeg-vgz = (super.ffmpeg-full.overrideAttrs (old: {
    pname = "ffmpeg-vgz";
    # We need both this and the openmpt patch below for ffmpegfs
    prePatch = ''
      sed -Ei '/"set subsong"/ s,i64 = -2,i64 = -1,' libavformat/libopenmpt.c
    '';
    patches = old.patches ++ [ ./ffmpeg-gme-loops.patch ];
  })).override {
    game-music-emu = self.libgme-vgz;
    libopenmpt = self.libopenmpt-subsong;
  };
  ffmpegfs = super.callPackage ../packages/ffmpegfs.nix {
    ffmpeg = self.ffmpeg-vgz;
  };
  koboredux-free = super.koboredux-free.overrideAttrs (old: {
    patches = old.patches ++ [
      ./kobo-balance-changes.patch
    ];
  });
  libgme-vgz = super.game-music-emu.overrideAttrs (old: {
    cmakeFlags = [ "-DENABLE_UBSAN=OFF" ];
    buildInputs = [ self.zlib ];
  });
  libopenmpt-subsong = super.libopenmpt.overrideAttrs {
    prePatch = ''
      sed -Ei 's,m_current_subsong = 0,m_current_subsong = all_subsongs,' libopenmpt/libopenmpt_impl.cpp
    '';
  };
  scanmem = super.scanmem.overrideAttrs (old: rec {
    patches = [ ./scanmem.patch ];
    src = super.fetchFromGitHub {
      owner  = "scanmem";
      repo   = "scanmem";
      rev    = "0def8b2abfcb922c9b647092394f079d29e299e1";
      sha256 = "sha256-+9za/XivOLDJTjUEt/6vv19DljQaqXx8YoElghx1qxc=";
    };
  });
  wxGTK32-curl = super.wxGTK32.overrideAttrs (old: rec {
    configureFlags = old.configureFlags ++ [ "--with-libcurl" ];
    buildInputs = old.buildInputs ++ [ self.curl ];
  });
  openxcom = super.openxcom.overrideAttrs (oldAttrs: rec {
    version = "7.0-oxce-2021.03.13";
    src = super.fetchFromGitHub {
      owner = "MeridianOXC"; repo = "OpenXcom";
      rev = "08d9eb908265b1fed482ff388d1ea7e8102d758f";
      sha256 = "0xwhzcqp1lhzralmipwk0xx2p94pa2gckh39cs4bg67cpqp3rnq0";
    };
    nativeBuildInputs = with self; [ cmake pkg-config ];
  });
  # yaft = super.yaft.overrideAttrs (_: { src = /home/bex/devel/devterm/yaft; }); # TODO: doesn't work when bootstrapping
}
