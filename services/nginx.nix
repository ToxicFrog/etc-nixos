# nginx virtual host configuration.
# Note that some nginx configs live in their associated service files,
# e.g. /maps is in minecraft.nix

{ config, pkgs, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "library.ancilla.ca" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = secrets.library-auth;
        locations."/".extraConfig = ''
          proxy_pass http://127.0.0.1:26657/;
        '';
        locations."/comics" = {
          root = "/ancilla/media";
          extraConfig = "autoindex on;";
        };
      };
      "ancilla" = {
        forceSSL = false;
        enableACME = false;
        # listen = [{ addr = "0.0.0.0"; port = 5634; ssl = false; }];
        locations."/plex" = {
          extraConfig = "return 301 http://192.168.86.34:32400/web;";
        };
        locations."/helix" = {
          root = "/srv/www";
        };
        locations."/oculus" = {
          root = "/srv/www";
        };
        # locations."/" = {
        #   root = "/ancilla/media";
        #   extraConfig = "autoindex on;";
        # };
      };
      "ancilla.lan" = {
        forceSSL = false;
        enableACME = false;
        # listen = [{ addr = "0.0.0.0"; port = 5634; ssl = false; }];
        locations."/plex" = {
          extraConfig = "return 301 http://192.168.86.34:32400/web;";
        };
        # locations."/" = {
        #   root = "/ancilla/media";
        #   extraConfig = "autoindex on;";
        # };
      };
      "ancilla.ancilla.ca" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = secrets.ancilla-auth;
        locations."/".root = "/srv/www";
        locations."/media" = {
          root = "/ancilla";
          extraConfig = "autoindex on;";
        };
        locations."/syncthing/".extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_pass              http://127.0.0.1:7962/;
          proxy_read_timeout      600s;
          proxy_send_timeout      600s;
        '';
      };
    };
  };
}
