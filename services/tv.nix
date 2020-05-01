# Configuration for media servers -- plex (video) and airsonic (music).

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  networking.firewall.allowedTCPPorts = [1900]; # DLNA discovery
  services = {
    jellyfin.enable = true;
    nginx.virtualHosts."tv.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      # basicAuth = secrets.plex-auth;
      locations."/" = {
        proxyPass = "http://localhost:8096/";
        extraConfig = "proxy_buffering off;";
      };
      locations."/socket" = {
        proxyPass = "http://localhost:8096/socket";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
        '';
      };
    };
  };
}
