# Configuration for local video streaming services.

{ config, pkgs, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [8096]; # DLNA media fetch
  networking.firewall.allowedUDPPorts = [1900 7359]; # DLNA discovery
  users.users.jellyfin.extraGroups = ["render"]; # HW video codecs
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = with pkgs; [libvdpau-va-gl vaapiVdpau];
  services = {
    jellyfin.enable = true;
    jellyfin.package = pkgs.jellyfin;
    nginx.virtualHosts."tv.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096/";
        extraConfig = "proxy_buffering off;";
      };
      locations."/socket" = {
        proxyPass = "http://127.0.0.1:8096/socket";
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
