# Configuration for HomeAssistant.
# Note that HASS does not cope well with running natively, so it's been put
# into a VM that is managed mutably with virt-manager, named station.
# Configuration for virt-manager overall is over in virtualization.nix.
# This file contains the various ancillary services needed by hass outside
# the VM, like the pubsub broker and audio sink.
{ config, pkgs, lib, ... }:

let
  mqtt-ports = [1883];
  dlna-ports = [1900 1901 4041 49494];
in {
  networking.firewall.allowedTCPPorts = mqtt-ports ++ dlna-ports;
  networking.firewall.allowedUDPPorts = mqtt-ports ++ dlna-ports;

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

  # 192.168.1.203 == station.ancilla.ca
  services.nginx.virtualHosts."home.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://192.168.1.203:8123/";
      proxyWebsockets = true;
    };
  };

  services.snapserver = {
    streams = {
      # Used for announcements from hass.
      # This is fed by gmediarender, below, which receives play commands over
      # DLNA.
      station = {
        type = "pipe";
        location = "/run/snapserver/station";
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

  services.gmediarender = {
    enable = true;
  };
  systemd.services.gmediarender.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.gmrender-resurrect}/bin/gmediarender --logfile=stdout --friendly-name=station-dlna --gstout-audiopipe 'audioresample ! audioconvert ! audio/x-raw,rate=48000,channels=2,format=S16LE ! wavenc ! filesink location=/run/snapserver/station'";

}
