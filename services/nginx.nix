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
