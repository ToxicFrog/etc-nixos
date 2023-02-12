# Configuration for library.ancilla.ca -- family ebooks (calibre) and comics
# (ubooquity) server.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  services.nginx.virtualHosts."library.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    basicAuth = secrets.library-auth;
    # Proxy to Calibre library. TODO: move calibre service configuration into
    # nix rather than running it out of my homedir.
    locations."/".proxyPass = "http://127.0.0.1:26657/";
    # Proxy to Codex comic library.
    locations."/comics" = {
      proxyPass = "http://127.0.0.1:9810/comics";
      proxyWebsockets = true;
      extraConfig = ''
        sub_filter '</head>' '<link rel="stylesheet" href="/codex-extra.css" /><script src="/codex-extra.js" defer></script></head>';
        sub_filter_last_modified on;
        sub_filter_once on;
      '';
    };
    locations."= /codex-extra.css".alias = ./codex-extra.css;
    locations."= /codex-extra.js".alias = ./codex-extra.js;
  };

  services.calibre-web = {
    enable = false;
    user = "rebecca";
    group = "users";
    options = {
      calibreLibrary = "/home/rebecca/Books/Calibre";
    };
    listen.port = 26657;
    listen.ip = "127.0.0.1";
  };

  users.users.codex = {
    isSystemUser = true;
    description = "Codex comic server";
    home = "/var/lib/codex";
    createHome = false;
    group = "codex";
    uid = 987;
  };
  users.groups.codex = { gid = 980; };
  virtualisation.oci-containers.containers.codex = {
    image = "ajslater/codex@sha256:3835da1e461dd06081d69daadbaa5be50b027577a4e1ebb8553665ae2cadfc61";
    user = "987:980";
    ports = ["9810:9810"];
    volumes = [
      "/var/lib/codex:/config"
      "/var/lib/codex:/.config"
      #"/ancilla/media/comics/.codex-libraries:/comics:ro"
      "/ancilla/media/comics:/ancilla/media/comics:ro"
      "/ancilla/media/books:/ancilla/media/books:ro"
    ];
    environment = {
      TZ = "America/Toronto";
      LOGLEVEL = "INFO";
    };
  };
}
