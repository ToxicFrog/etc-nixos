# Configuration for HomeAssistant.
# Note that HASS does not cope well with running natively, so it's been put
# into a VM that is managed mutably with virt-manager, named station.
# Configuration for virt-manager overall is over in virtualization.nix.
# This file contains the various ancillary services needed by hass outside
# the VM, like the pubsub broker and audio sink.
{ config, pkgs, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  networking.firewall.allowedTCPPorts = [
    1883 # MQTT
    6600 # MPD
  ];
  networking.firewall.allowedUDPPorts = [1883];

  # MQTT server
  # Currently not visible to the internet and does not require authentication.
  # TODO: harden this, and maybe expose it to the internet.
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  services.nginx.upstreams.station = {
    servers."station.ancilla.ca:8123" = {};
  };

  services.nginx.virtualHosts."home.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://station/";
      proxyWebsockets = true;
    };
  };

  services.snapserver = {
    enable = true;
    openFirewall = true;
    tcp.enable = true;
    http.enable = false;
    streams = {
      # Used for announcements from hass.
      station = {
        type = "pipe";
        location = "/run/snapserver/station";
        sampleFormat = "48000:16:2";
        query.codec = "flac";
        query.dryout_ms = "1000";
      };
      # Used for airsonic/gonic jukebox mode.
      music = {
        type = "pipe";
        location = "/run/snapserver/music";
        sampleFormat = "48000:16:2";
        query.codec = "flac";
        query.dryout_ms = "1000";
      };
      # All audio, but with station announcements taking priority.
      all = {
        type = "meta";
        location = "/station/music";
        query.codec = "flac";
        query.dryout_ms = "1000";
      };
    };
  };

  # MPD is used to remotely push audio to the snapserver. The curl input allows
  # hass to send it a URL, at which point mpd will stream the URL, transcode it
  # if needed, and send the data to the snapserver on the "station" channel.
  systemd.services.mpd.requires = [ "snapserver.service" ];
  services.mpd = {
    enable = true;
    network.listenAddress = "any";
    extraConfig = ''
      default_permissions "read,add,control"
      input {
        plugin "curl"
      }
      audio_output {
        type        "fifo"
        name        "snapserver"
        path        "/run/snapserver/station"
        format      "48000:16:2"
        mixer_type  "software"
      }
    '';
  };
}

  # users.users.hass = {
  #   isSystemUser = true;
  #   description = "HomeAssistant";
  #   home = "/var/lib/hass";
  #   createHome = false;
  #   group = "hass";
  #   extraGroups = ["dialout" "audio" "video"];
  #   uid = 286;
  # };
  # users.groups.hass = { gid = 286; };
