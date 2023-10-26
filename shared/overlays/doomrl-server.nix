self: super:

let
  server-path = "/srv/doomrl";
  src = /home/rebecca/devel/doomrl-server;
in {
  doomrl-server = self.stdenv.mkDerivation {
    name = "doomrl-server";
    src = if src != null then src else self.fetchFromGitHub {
      owner = "toxicfrog";
      repo = "doomrl-server";
      rev = "6ad7e07cc8fe2b87b6492f00b4c354a2f0392654";
      sha256 = "03cafza49cy02imc38zx4bfdkny3v7gfs4hgx7sarsbs4igk04qb";
    };

    nativeBuildInputs = with self; [gnumake git lua5_3];
    buildInputs = with self; [SDL];
    deps = with self; [python3 inetutils less ncurses nano];

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    buildPhase = ''make -C ttysound DRL_SOUND_CONFIG=${self.doomrl}/opt/doomrl/soundhq.lua'';
    installPhase = ''
      mkdir -p "$out/share"
      cp -a . "$out/share/doomrl-server"
      mkdir -p "$out/share/doomrl-server/www/sfx/"
      for sfx in ${self.doomrl}/opt/doomrl/wavhq/*.wav; do
        flac="$(${self.coreutils}/bin/basename "$sfx" | ${self.gnused}/bin/sed -E "s,wav$,flac,")"
        ${self.ffmpeg}/bin/ffmpeg -hide_banner -loglevel error -i "$sfx" "$out/share/doomrl-server/www/sfx/$flac"
      done
      ln -s ${self.doomrl}/opt/doomrl/mp3 "$out/share/doomrl-server/www/music"
    '';
  };
}
