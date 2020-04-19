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
    locations."/comics".proxyPass = "http://127.0.0.1:2202";
    locations."/comics/admin".proxyPass = "http://127.0.0.1:2203";
    locations."= /ubreader.js".alias = pkgs.copyPathToStore ./ubreader.js;
    locations."/comics".extraConfig = ''
      sub_filter '</head>' '<script type="text/javascript" src="/ubreader.js"></script></head>';
      sub_filter_last_modified on;
      sub_filter_once on;
    '';
  };

  users.users.ubooquity = {
    isSystemUser = true;
    description = "Ubooquity comic server";
    home = "/srv/ubooquity";
    createHome = false;
  };

  systemd.services.ubooquity = {
    description = "Ubooquity Comic Reader";
    after = ["network-online.target" "local-fs.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "ubooquity";
      Group = "nogroup";
      ExecStart = "${pkgs.jre}/bin/java -jar Ubooquity.jar --headless --remoteadmin";
      WorkingDirectory = "/srv/ubooquity";
    };
  };
}
