# Configuration for media servers -- plex (video) and airsonic (music).

{ config, pkgs, lib, ... }:

{
  users.users.airsonic.createHome = lib.mkForce false;

  services = {
    airsonic = {
      enable = true;
      maxMemory = 512;
      home = "/srv/airsonic";
    };

    nginx.virtualHosts."music.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4040/";
        extraConfig = ''
          proxy_redirect          http:// https://;
          proxy_read_timeout      600s;
          proxy_send_timeout      600s;
          add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' www.gstatic.com; img-src 'self' *.akamaized.net; style-src 'self' 'unsafe-inline' fonts.googleapis.com; font-src 'self' fonts.gstatic.com; frame-src 'self'; object-src 'none'";
        '';
      };
    };
  };
}
