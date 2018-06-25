self: super:

{
  elinks = super.elinks.overrideAttrs (oldAttrs: {
    name = "elinks-0.12pre6+f4a58ba";

    src = self.fetchFromGitHub {
      repo = "elinks";
      owner = "nabetaro";
      rev = "master";
      sha256 = "1avcky008x1s3sgfbhwvk89h0fgj82jhnr0bxk4vhml5mm06c7bl";
    };

    nativeBuildInputs = [ self.autoreconfHook self.pkgconfig ];
    buildInputs = with self; [
      ncurses
      xlibsWrapper
      bzip2
      zlib
      gnutls
      spidermonkey_1_8_5
      gpm
      perl
      lua
      tre
      libgcrypt
      # python
    ];

    patches = [];

    postPatch = ''
      sed -E -i 's,AC_PROG_CC,AC_USE_SYSTEM_EXTENSIONS\nAC_PROG_CC,' configure.in
      cat config/m4/*.m4 > acinclude.m4
    '';

    configureFlags = [
      "--enable-finger"
      "--enable-html-highlight"
      "--enable-gopher"
      "--enable-cgi"
      "--enable-bittorrent"
      "--enable-nntp"
      "--with-gnutls=${self.gnutls.dev}"
      "--with-bzip2=${self.bzip2.dev}"
      # "--with-tre=${self.tre.dev}"
      "--with-perl"
      # "--with-lua"
      # "--with-python"
      "--with-spidermonkey=${self.spidermonkey_1_8_5}"
    ];
  });
}
