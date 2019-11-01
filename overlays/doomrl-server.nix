self: super:

let
  server-path = "/srv/doomrl";
in {
  doomrl-server = self.stdenv.mkDerivation {
    name = "doomrl-server";
    src = self.fetchFromGitHub {
      owner = "toxicfrog";
      repo = "doomrl-server";
      rev = "master";
      sha256 = "02wfkj4zjqjlh2cyfrcqjb7q87hyqsrb4y0756lhw5ag53a5ddc6";
    };

    nativeBuildInputs = with self; [gnumake git];
    buildInputs = with self; [SDL];
    deps = with self; [python3 telnet less];

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    buildPhase = ''make -C ttysound'';
    installPhase = ''
      mkdir -p $out/share/
      cp -a . "$out/share/doomrl-server"
    '';
  };
}
