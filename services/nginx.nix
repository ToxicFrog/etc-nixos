# nginx virtual host configuration.
# Note that some nginx configs live in their associated service files,
# e.g. /maps is in minecraft.nix

{ config, pkgs, lib, ... }:

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
        locations."/".proxyPass = "http://127.0.0.1:26657/";
        locations."/comics".proxyPass = "http://127.0.0.1:2202";
        locations."/comics/admin".proxyPass = "http://127.0.0.1:2203";
        locations."= /ubreader.js".alias = pkgs.copyPathToStore ./ubreader.js;
        locations."/comics".extraConfig = ''
          sub_filter '</head>' '<script type="text/javascript" src="/ubreader.js"></script></head>';
          sub_filter_last_modified on;
          sub_filter_once on;
        '';
      };
      "ancilla" = {
        locations."/" = {
          extraConfig = "return 301 https://ancilla.ancilla.ca/;";
        };
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
          proxy_pass              http://127.0.0.1:8384/;
          proxy_read_timeout      600s;
          proxy_send_timeout      600s;
        '';
        locations."/share/" = {
          root = "/srv/www";
          extraConfig = ''
            add_header 'Access-Control-Allow-Origin' '*';
            auth_basic off;
            autoindex on;
          '';
        };
        locations."/favicon.ico" = {
          root = "/srv/www";
          extraConfig = ''
            auth_basic off;
          '';
        };
      };
    };
  };
}
