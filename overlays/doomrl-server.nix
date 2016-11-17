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
      sha256 = "1kxkk6jj2b6hym2kdw5ybl3qksgad80f8wjkky90fybclngca3cc";
    };

    nativeBuildInputs = with self; [gnumake];
    buildInputs = with self; [SDL];
    deps = with self; [python3 telnet less];

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    buildPhase = ''make -C ttysound'';
    installPhase = ''
      # ls -ltrAh
      # pwd
      # echo "out=$out"
      # stat $out
      mkdir -p $out/share/
      cp -a . "$out/share/doomrl-server"
    '';
  };
}
