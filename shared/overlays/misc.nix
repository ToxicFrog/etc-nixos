self: super:

{
  # TODO: replace this with gonic if and when I can.
  airsonic = super.airsonic.overrideAttrs (_: rec {
    version = "11.0.2-kagemomiji";
    name = "airsonic-advanced-${version}";
    src = super.fetchurl {
      url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/11.0.2/airsonic.war";
      sha256 = "PgErtEizHraZgoWHs5jYJJ5NsliDd9VulQfS64ackFo=";
    };
  });
  doomrl = super.callPackage ../packages/doomrl.nix {};
  etcd = super.etcd_3_4; # TODO: try upgrading to latest stable (3.5)
  ffmpeg-vgz = (super.ffmpeg-full.overrideAttrs { pname = "ffmpeg-vgz"; })
    .override { game-music-emu = self.libgme-vgz; };
  libgme-vgz = super.game-music-emu.overrideAttrs (old: {
    cmakeFlags = [ "-DENABLE_UBSAN=OFF" ];
    buildInputs = [ self.zlib ];
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
  slashem9 = super.callPackage ../packages/slashem9/slashem9.nix {};
  weechat = super.weechat.override {
    configure = { availablePlugins, ... }: {
      scripts = with self.weechatScripts; [ weechat-matrix multiline ];
    };
  };
}
