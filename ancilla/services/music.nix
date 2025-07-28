# Configuration for music streaming.
# This handles both out-of-the-house streaming to individual devices (via gonic
# and polaris) and in-house streaming to speakers (via mpd and snapcast).

{ config, pkgs, lib, secrets, ... }:

let
in {
  # Out-of-the-house configuration.
  #
  # Polaris, on music.ancilla.ca, serves a web interface that can be used to
  # play music in the browser. This is the most convenient way to use it from a
  # desktop or laptop.
  #
  # Gonic, on music.ancilla.ca/gonic, serves a Subsonic-compatible API suitable
  # for use by Subsonic/OpenSubsonic clients. I use this to listen to music on
  # my phone via Ultrasonic, which, while a bit clunky, supports the critical
  # feature of downloading music for offline listening.
  services.nginx.virtualHosts."music.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3003/";
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
    locations."/gonic/" = {
      proxyPass = "http://127.0.0.1:4747/";
      proxyWebsockets = true;
    };
  };

  services.polaris = {
    enable = true;
    port = 3003;
    settings = {
      reindex_every_n_seconds = 7*24*60*60; # weekly
      album_art_pattern = "(cover|front|folder)\.(jpeg|jpg|png|bmp|gif)";
      mount_dirs = [
        { name = "ancilla"; source = "/ancilla/media/music/.srv"; }
        { name = "podcasts"; source = "/ancilla/media/music/Podcasts"; }
        { name = "ancilla-archive"; source = "/ancilla/media/music/ancilla-archive"; }
      ];
      users = secrets.polaris.users;
    };
  };
  # Needed for 0.15.0 until the official update lands in nixpks
  systemd.services.polaris.serviceConfig.WorkingDirectory = "/var/lib/polaris";

  systemd.services.gonic.serviceConfig.BindReadOnlyPaths = lib.mkForce [
    "-/etc/resolv.conf"
    "-/etc/ssl/certs/ca-certificates.crt"
    builtins.storeDir
    config.services.gonic.settings.music-path
    config.services.gonic.settings.podcast-path
    "/ancilla/media/music/Library"  # many of the files in the library are symlinks into this
  ];
  systemd.services.gonic.serviceConfig.BindPaths = [
    config.services.gonic.settings.playlists-path
  ];
  systemd.services.gonic.after = ["network-online.target" "local-fs.target"];
  systemd.services.gonic.requires = ["network-online.target" "local-fs.target"];
  services.gonic = {
    enable = true;
    settings = {
      "music-path" = [
        "/ancilla/media/music/.srv"
        "/ancilla/media/music/Podcasts"
        "/ancilla/media/music/ancilla-archive/library"
      ];
      "podcast-path" = "/var/empty"; # TODO: podcasts?
      "playlists-path" = "/ancilla/media/music/Playlists";
      "scan-at-start-enabled" = false;
      "scan-interval" = 60; # in minutes
      "scan-watcher-enabled" = true;
      "jukebox-enabled" = false;
      "proxy-prefix" = "/gonic";
    };
  };

  # In-house music.
  #
  # This is done via Snapcast. Internally, it listens to a fifo, which other
  # things can feed music to; over in smarthome.nix there's also configuration
  # for an "announcements fifo" which takes precedence over the music one, for
  # TTS traffic.
  #
  # To actually get music playing, and control the snapnet, we run the web UI
  # on snapcast.ancilla.ca (accessible only from inside the lan) and the MPD
  # frontend mympd on snapcast.ancilla.ca/mpd. Anything you play on mpd (via
  # that frontend or via other clients like ncmpcpp) goes to the music fifo and
  # thence to the snapserver.
  services.pipewire.enable = false;
  services.pulseaudio.enable = false;
  hardware.alsa.enablePersistence = true;
  environment.etc."asound.conf".text = ''
    pcm.!default {
        type null
    }
  '';

  services.snapserver = {
    enable = true;
    openFirewall = true;
    tcp.enable = true;
    http.enable = true;
    streams = {
      # Used for mopidy/mpd local music playback.
      music = {
        type = "pipe";
        location = "/run/snapserver/music";
        sampleFormat = "48000:16:2";
        query.codec = "flac";
        query.dryout_ms = "1000";
      };
    };
  };

  systemd.services.snapclient = {
    requires = [ "snapserver.service" ];
    after = [ "snapserver.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.snapcast}/bin/snapclient -h ancilla -s sysdefault:CARD=SoundBar";
      Restart = "always";
      RestartSec = "60s";
    };
  };

  services.mpd = {
    enable = true;
    musicDirectory = "/ancilla/media/music/.srv";
    # playlistDirectory = "/ancilla/media/music/Playlists/mpd";
    extraConfig = ''
      audio_output {
        type "fifo"
        name "snapcast"
        format "48000:16:2"
        mixer_type "software"
        path "${config.services.snapserver.streams.music.location}"
      }
    '';
  };
  services.mympd = {
    enable = true;
    settings = {
      http_port = 6008;
      mympd_uri = "https://snapcast.ancilla.ca/mpd";
    };
  };

  services.nginx.virtualHosts."snapcast.ancilla.ca" = {
    forceSSL = false;
    enableACME = false;
    extraConfig = ''
      # Internal LAN
      deny 192.168.1.1;
      allow 192.168.1.0/24;
      # Tailscale
      allow 100.64.0.0/24;
      deny all;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:1780/";
      proxyWebsockets = true;
    };
    locations."/mpd/" = {
      proxyPass = "http://127.0.0.1:6008/";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_redirect / /mpd/;
      '';
    };
  };

}
