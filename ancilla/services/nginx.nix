# nginx virtual host configuration.
# Note that some nginx configs live in their associated service files,
# e.g. /maps is in minecraft.nix

{ config, pkgs, lib, secrets, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "ancilla" = {
        locations."/" = {
          extraConfig = "return 301 https://ancilla.ancilla.ca/;";
        };
      };
      "ancilla.ancilla.ca" = {
        forceSSL = true;
        enableACME = true;
        basicAuth = secrets.auth.nginx.ancilla;
        locations."/".root = "/srv/www";
        locations."/media" = {
          root = "/ancilla";
          extraConfig = "autoindex on;";
        };
        locations."/syncthing/bex/".extraConfig = ''
          proxy_pass              http://127.0.0.1:21171/;
          proxy_read_timeout      600s;
          proxy_send_timeout      600s;
        '';
        locations."/syncthing/alex/".extraConfig = ''
          proxy_pass              http://127.0.0.1:21148/;
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
        locations."/pub/" = {
          root = "/srv/www";
          extraConfig = ''
            auth_basic off;
            autoindex on;
          '';
        };
        locations."/tyria".return = "302 /tyria/";
        locations."/tyria/".extraConfig = ''
          proxy_pass    http://localhost:8099/;
          add_header    'X-Base-URL' '/tyria';
          sub_filter    'href="/' 'href="/tyria/';
          sub_filter_last_modified on;
          sub_filter_once off;
        '';
        # etcd
        locations."/v3/kv/".extraConfig = ''
          proxy_pass http://127.0.0.1:2379/v3/kv/;
          proxy_set_header Authorization "";
        '';
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
