# Configuration for music streaming.
# At the moment this just means Airsonic, with streaming to the browser via the
# web client and to mobile devices via Ultrasonic.
# It may in the future include some sort of whole-home sound system using MPD
# and SnapCast, or something.

{ config, pkgs, lib, ... }:

let
  ffprobe-subsong-wrapper = pkgs.writeShellScriptBin "ffprobe" ''
    exec ${pkgs.ffmpeg-vgz}/bin/ffprobe -subsong all "$@"
  '';
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
      #"${pkgs.ffmpeg-vgz}/bin/ffprobe"
      "${ffprobe-subsong-wrapper}/bin/ffprobe"
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

  systemd.services.gonic.serviceConfig.BindReadOnlyPaths =
      [ "-/etc/resolv.conf" ];
  systemd.services.gonic.serviceConfig.BindPaths =
      [ "-/run/snapserver/music" ];
  services.gonic = {
    enable = true;
    settings = {
      "music-path" = [
        "/ancilla/media/music/Library"
        # "/ancilla/media/music/ancilla-archives/library/albums"
      ];
      "podcast-path" = "/ancilla/media/music/Podcasts";
      #"playlists-path" = "/ancilla/media/music/Playlists";
      "scan-at-start-enabled" = true;
      "scan-watcher-enabled" = true;
      "jukebox-enabled" = true;  # TODO: wire up to snapcast
      "jukebox-mpv-extra-args" = "--audio-channels=stereo --audio-samplerate=48000 --audio-format=s16 --ao=pcm --ao-pcm-file=/run/snapserver/music";
      "proxy-prefix" = "/gonic";
    };
  };

  services.nginx.virtualHosts."staging.ancilla.ca" = {
    # forceSSL = true;
    # enableACME = true;
    locations."/" = {
      root = "/srv/www/airsonic-refix/";
      tryFiles = "$uri $uri/ /index.html";
    };
    locations."/gonic/" = {
      proxyPass = "http://127.0.0.1:4747/";
    };
    locations."/rest/" = {
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
}
