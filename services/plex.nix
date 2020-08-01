# Configuration for media servers -- plex (video) and airsonic (music).

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  services = {
    plex = {
      enable = false;
      openFirewall = true;
      dataDir = "/srv/plex";
      extraPlugins = [
        "/srv/plex/plugins/YouTubeTV.bundle"
      ];
    };

    nginx.virtualHosts."ancilla".locations."/plex" = {
      extraConfig = "return 301 https://plex.ancilla.ca/web/index.html;";
    };
    nginx.virtualHosts."ancilla.lan".locations."/plex" = {
      extraConfig = "return 301 https://plex.ancilla.ca/web/index.html;";
    };
    nginx.virtualHosts."plex.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      basicAuth = secrets.plex-auth;
      extraConfig = ''
        #Forward real ip and host to Plex
        proxy_set_header Host "127.0.0.1:32400";
        proxy_set_header Referer "";
        proxy_set_header Origin "http://127.0.0.1:32400";
        proxy_set_header Sec-WebSocket-Extensions $http_sec_websocket_extensions;
        proxy_set_header Sec-WebSocket-Key $http_sec_websocket_key;
        proxy_set_header Sec-WebSocket-Version $http_sec_websocket_version;

        #Websockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";

        #Buffering off send to the client as soon as the data is received from Plex.
        proxy_redirect off;
        proxy_buffering off;
      '';
      locations."= /".extraConfig = ''
        return 301 https://plex.ancilla.ca/web/index.html;
      '';
      locations."/".proxyPass = "http://127.0.0.1:32400";
    };
  };

  # Automatically turn off Helix's USB ports, thus shutting off the Chromecast,
  # every night, so that it doesn't wake the screen back up and blast the entire
  # room with light when it reboots for updates at 2am every morning.
  # Seriously, why can't you turn that off?
  # systemd.services.chromecast-off = {
  #   startAt = ["*-*-* 01:00:00"];
  #   script = ''echo 1-1 | ${pkgs.openssh}/bin/ssh root@helix tee /sys/bus/usb/drivers/usb/unbind'';
  # };
  # systemd.services.chromecast-on = {
  #   startAt = ["*-*-* 09:00:00"];
  #   script = ''echo 1-1 | ${pkgs.openssh}/bin/ssh root@helix tee /sys/bus/usb/drivers/usb/bind'';
  # };
}
