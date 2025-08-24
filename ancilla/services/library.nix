# Configuration for library.ancilla.ca -- family ebooks (calibre) and comics
# (ubooquity) server.

{ config, pkgs, lib, secrets, ... }:

{
  services.nginx.virtualHosts."library.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    # basicAuth = secrets.auth.nginx.library;
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
    enable = true;
    listen.port = 26657;
    listen.ip = "127.0.0.1";
  };
  # TODO: daily at midnight:
  # rsync --delete-after --chown calibre-web:calibre-web --chmod D0550,F0440 ~bex/Books/Calibre/ /srv/calibre-web/

  users.users.codex = {
    isSystemUser = true;
    description = "Codex comic server";
    home = "/var/lib/codex";
    createHome = false;
    group = "codex";
    uid = 987;
  };
  users.groups.codex = { gid = 980; };

  # Codex is installed via pip, because docker is full of spiders.
  # This is done as the codex user (sudo -u codex bash),
  # in a nix shell (nix-shell -p python3Packages.{pip,virtualenv}).
  # The venv is initialized with:
  # $ virtualenv codex-venv
  # Codex is then installed with:
  # $ codex-venv/bin/pip install codex
  # And then executed with:
  # $ codex-venv/bin/codex
  systemd.services.codex = {
    description = "codex comic server";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    requires = ["network-online.target"];
    script = ''
      codex-venv/bin/codex
    '';
    environment = {
      # Needed so libmupdf, which comes with codex, can find libstd++.
      LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };
    serviceConfig = {
      User = "codex";
      Group = "codex";
      WorkingDirectory = "~";
      Restart = "always";
      RestartSec = "30";
    };
  };
}
