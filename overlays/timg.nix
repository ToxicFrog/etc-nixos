self: super:

{
  timg = self.stdenv.mkDerivation {
    name = "timg";
    src = self.fetchFromGitHub {
      owner = "hzeller";
      repo = "timg";
      rev = "dcd0c4d3d3d20280726314811ade4b74731b921c";
      sha256 = "0ycfsxmzw8mq1hs7kvsssi678zkszi948sh3wskq2wvykf7j6lx3";
    };

    nativeBuildInputs = with self; [gnumake];
    buildInputs = with self; [libwebp graphicsmagick];
    # deps = with self; [python3 telnet less];

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    buildPhase = ''make -C src'';
    installPhase = ''
      mkdir -p "$out/bin/"
      cp -a src/timg "$out/bin/timg"
    '';
  };
}
