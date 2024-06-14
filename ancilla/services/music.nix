# Configuration for music streaming.
# At the moment this just means Airsonic, with streaming to the browser via the
# web client and to mobile devices via Ultrasonic.
# It may in the future include some sort of whole-home sound system using MPD
# and SnapCast, or something.

{ config, pkgs, lib, ... }:

let
  # include_extensions = (builtins.concatMap
  #   (s: ["include_extensions=${s}" "include_extensions=${lib.strings.toUpper s}"])
  #   ["ahx" "dbm" "gdm" "hvl" "imf" "it" "mo3" "mod" "mpc" "mptm" "mtm" "s3m" "umx" "vgm" "vgz" "xm"]);
  include_extensions =
    (lib.strings.concatStrings (lib.strings.intersperse ","
      (builtins.concatMap
        (s: ["${s}" "${lib.strings.toUpper s}"])
        ["ahx" "dbm" "gdm" "hvl" "imf" "it" "mo3" "mod" "mpc" "mptm" "mtm" "s3m" "umx" "vgm" "vgz" "xm"])));
  mstreamConfig = builtins.toJSON {
    secret = "+UW1ciKs1J84FHdTUhaVlk/aJ4bOMlGJhA3cXxI+FK+xNK6AwKs7nPhYCGaA3h4m0mkwgVeCA86nomMziK9B96QmK3t/ZdEYPtUltVHrY5+sxOGT6qr7iFHh/CvAvF2Sk3cw03fxVT;+eJvSsIbh5i2vMyMVcI1NlbCy2hf5x8KE=";
    port = 3003;
    noUpload = true;
    writeLogs = false;
    folders = {
      ancilla = { root = "/ancilla/media/music/.srv"; };
      podcasts = { root = "/ancilla/media/music/Podcasts"; };
      archive = { root = "/ancilla/media/music/ancilla-archive"; };
      quetzalcoatl = { root = "/ancilla/media/music/quetzalcoatl"; };
    };
    storage = {
      albumArtDirectory = "art";
      dbDirectory = "db";
      logsDirectory = "/var/log/mstream";
    };
    transcode = {
      enabled = false;
      ffmpegDirectory = "${pkgs.ffmpeg-vgz}/bin/";
      defaultCodec = "opus";
      defaultBitrate = "128k";
    };
    users = secrets.auth.mstream;
  };
  mstreamConfigFile = pkgs.writeText "mstream.conf.json" mstreamConfig;
in {
  users.users.airsonic.createHome = lib.mkForce false;

  # DLNA
  # networking.firewall.allowedTCPPorts = [1900 1901 4041];
  # networking.firewall.allowedUDPPorts = [1900 1901 4041];

  services.airsonic = {
    enable = true;
    maxMemory = 4096;
    jre = pkgs.jdk17;
    home = "/srv/airsonic";
    transcoders = [
      "${pkgs.ffmpeg-vgz}/bin/ffmpeg"
      "${pkgs.ffmpeg-vgz}/bin/ffprobe"
    ];
  };

  services.nginx.virtualHosts."music.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4040/";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_redirect          http:// https://;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
        proxy_buffering         off;
        proxy_request_buffering off;
        #proxy_set_header        Host $host;
        client_max_body_size    0;
      '';
    };
  };

  users.users.mstream = {
    isSystemUser = true;
    description = "mstream service account";
    home = "/var/lib/mstream";
    group = "mstream";
    createHome = true;
  };
  users.groups.mstream = {};
  # environment.etc."mstream.conf.json".text = mstreamConfig;

  # mstream patch
  # document.querySelectorAll('div.dirz span.songDropdown').forEach(x => x.click())
  # need to hook the addAll function, which only works on albums, not dirs
  # and then in css
  # div.song-button-box { height: 100% }
  # div.song-button-box > span { height: 100% }
  # div.song-button-box > span > svg { height: 100%; width: 75% }
  # div.playlist-item { padding-top: 0.4em; padding-bottom: 0; }
  systemd.services.mstream = {
    description = "mStream music server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    script = ''
      mkdir -p art db
      cp -n ${mstreamConfigFile} mstream.conf.json || true
      ${pkgs.mstream}/bin/mstream -j mstream.conf.json
    '';
    serviceConfig = {
      User = "mstream";
      Group = "mstream";
      WorkingDirectory = "~";
      Restart = "always";
      RestartSec = "30";
    };
  };

  # TODO: replace airsonic with gonic + mstream
  # mstream uses / and /api for all its stuff
  # the subsonic API served by gonic uses /rest, so we can host them both
  # on the same domain by routing /rest to the gonic port and
  # everything else to mstream
  # though this may make it hard to access the gonic admin UI
  # mstream's admin UI is at /admin, not sure where gonic's is

  systemd.services.gonic.serviceConfig.BindReadOnlyPaths = lib.mkForce [
    "-/etc/resolv.conf"
    "-/etc/ssl/certs/ca-certificates.crt"
    builtins.storeDir
    config.services.gonic.settings.music-path
    config.services.gonic.settings.podcast-path
  ];
  systemd.services.gonic.serviceConfig.BindPaths = [
    "-/run/snapserver/music"
  ];
  systemd.services.gonic.after = ["network-online.target" "local-fs.target"];
  services.gonic = {
    enable = true;
    settings = {
      "music-path" = [
        "/ancilla/media/music/.srv"
        "/ancilla/media/music/Podcasts"
        # "/ancilla/media/music/ancilla-archives/library/albums"
      ];
      "podcast-path" = "/var/empty";
      #"playlists-path" = "/ancilla/media/music/Playlists";
      "scan-at-start-enabled" = false;
      "scan-interval" = 60; # in minutes
      "scan-watcher-enabled" = true;
      "jukebox-enabled" = true;
      "jukebox-mpv-extra-args" = "--audio-channels=stereo --audio-samplerate=48000 --audio-format=s16 --ao=pcm --ao-pcm-file=/run/snapserver/music";
      "proxy-prefix" = "/gonic";
    };
  };

  services.nginx.virtualHosts."staging.ancilla.ca" = {
    # forceSSL = true;
    # enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3003/";
      proxyWebsockets = true;
    };
    # locations."/" = {
    #   root = "/srv/www/airsonic-refix/";
    #   tryFiles = "$uri $uri/ /index.html";
    # };
    locations."/gonic/" = {
      proxyPass = "http://127.0.0.1:4747/";
    };
    # locations."/rest/" = {
    #   proxyPass = "http://127.0.0.1:4040/";
    #   proxyWebsockets = true;
    #   extraConfig = ''
    #     proxy_redirect          http:// https://;
    #     proxy_read_timeout      600s;
    #     proxy_send_timeout      600s;
    #     proxy_buffering         off;
    #     proxy_request_buffering off;
    #     #proxy_set_header        Host $host;
    #     client_max_body_size    0;
    #   '';
    # };
  };

  sound.enable = true;
  services.pipewire.enable = false;
  hardware.pulseaudio.enable = false;
  sound.extraConfig = ''
    pcm.!default {
        type null
    }
  '';
}
