# Configuration for library.ancilla.ca -- family ebooks (calibre) and comics
# (ubooquity) server.

{ config, pkgs, lib, secrets, ... }:

{
  services.nginx.virtualHosts."library.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    basicAuth = secrets.auth.nginx.library;
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
    user = "bex";
    group = "users";
    options = {
      calibreLibrary = "/home/bex/Books/Calibre";
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
    # image = "ajslater/codex@sha256:1faf2ca1c75ec09903fe6a3c902e1ce3622b6e17d3223fbc0631dc056b488416"; # 1.5.0 rc2
    image = "ajslater/codex@sha256:57f77e79441b0b200c6c17339a89b6448281df6f645f86b6fb39870dba2db492"; # 1.4.3
    user = "987:980";
    ports = ["9810:9810"];
    extraOptions = ["--memory=1g"];
    volumes = [
      "/var/lib/codex:/config"
      "/var/lib/codex:/.config"
      "/ancilla/media/comics:/ancilla/media/comics:ro"
      "/ancilla/media/books:/ancilla/media/books:ro"
    ];
    environment = {
      TZ = "America/Toronto";
      LOGLEVEL = "INFO";
    };
  };
}
