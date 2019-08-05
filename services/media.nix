# Configuration for media servers -- plex (video) and airsonic (music).

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
{
  users.users.airsonic.createHome = lib.mkForce false;

  services = {
    airsonic = {
      enable = true;
      maxMemory = 256;
      home = "/srv/airsonic";
    };

    plex = {
      enable = true;
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
        #proxy_set_header X-Real-IP $remote_addr;
        #When using ngx_http_realip_module change $proxy_add_x_forwarded_for to '$http_x_forwarded_for,$realip_remote_addr'
        #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #proxy_set_header X-Forwarded-Proto $scheme;
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
      locations."/".extraConfig = ''
        proxy_pass    http://127.0.0.1:32400;
      '';
    };
    nginx.virtualHosts."music.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/".extraConfig = ''
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_set_header        X-Forwarded-Host $host;
        proxy_pass              http://127.0.0.1:4040;
        proxy_redirect          http:// https://;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' www.gstatic.com; img-src 'self' *.akamaized.net; style-src 'self' 'unsafe-inline' fonts.googleapis.com; font-src 'self' fonts.gstatic.com; frame-src 'self'; object-src 'none'";
      '';
    };
  };
}
