self: super:

let
  server-path = "/srv/doomrl";
  # src = /home/rebecca/devel/doomrl-server;
  src = null;
in {
  doomrl-server = self.stdenv.mkDerivation {
    name = "doomrl-server";
    src = if src != null then src else self.fetchFromGitHub {
      owner = "toxicfrog";
      repo = "doomrl-server";
      rev = "10aaa4e6c3b0bf03301738a95ec361d453f11549";
      hash = "sha256-5eW2Cy7qLXmFnH6l+Fo4XvAoIgYVibw6ki9aW3jahj0=";
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
