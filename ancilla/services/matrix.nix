{ config, pkgs, lib, unstable, ... }:

{
  services.matrix-conduit = {
    enable = true;
    extraEnvironment = {
      RUST_MIN_STACK = "16777216";
    };
    package = unstable.matrix-conduit;
    settings.global = {
      server_name = "ancilla.ca";
      address = "127.0.0.1";
      port = 6167;
      max_request_size = 20000000;
      allow_registration = false;
      allow_encryption = true;
      allow_federation = true;
      trusted_servers = ["matrix.org"];
      # database_path = "/srv/matrix/conduit-db"
    };
  };

  systemd.services.matrix2051 = {
    description = "Matrix2051 IRC gateway for Matrix";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target" "conduit.service"];
    script = ''
      ${pkgs.matrix2051}/bin/matrix2051 start
    '';
    serviceConfig = {
      Restart = "on-failure";
    };
    environment = {
      RELEASE_COOKIE = "matrix2051";
      RELEASE_TMP = "/var/empty";
    };
  };

  systemd.services.mautrix-discord = {
    description = "Matrix-to-Discord puppeting bridge";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target" "conduit.service"];
    serviceConfig = {
      DynamicUser = "true";
      ExecStart = "${unstable.mautrix-discord}/bin/mautrix-discord";
      Restart = "on-failure";
      RestartSec = "30s";
      StateDirectory = "mautrix-discord";
      User = "mautrix-discord";
      WorkingDirectory = "/var/lib/mautrix-discord";
    };
  };

  systemd.services.mautrix-googlechat = {
    description = "Matrix-to-Googlechat puppeting bridge";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target" "conduit.service"];
    serviceConfig = {
      DynamicUser = "true";
      ExecStart = "${unstable.mautrix-googlechat}/bin/mautrix-googlechat";
      Restart = "on-failure";
      RestartSec = "30s";
      StateDirectory = "mautrix-googlechat";
      User = "mautrix-googlechat";
      WorkingDirectory = "/var/lib/mautrix-googlechat";
    };
  };

  services.nginx.virtualHosts."matrix.ancilla.ca" = {
    enableACME = true;
    forceSSL = true;
    http2 = true;
    extraConfig = ''
      http2_max_requests 100000;
    '';
    locations."/_matrix/" = {
      proxyPass = "http://127.0.0.1:6167$request_uri";
      extraConfig = ''
        client_max_body_size 32M;
      '';
    };
    locations."= /.well-known/matrix/client" = {
      alias = pkgs.writeText "matrix-wk-client" ''
        { "m.homeserver": { "base_url": "https://matrix.ancilla.ca" } }
      '';
      extraConfig = "add_header Access-Control-Allow-Origin *;";
    };
    locations."= /.well-known/matrix/server" = {
      alias = pkgs.writeText "matrix-wk-server" ''
        { "m.server": "matrix.ancilla.ca:443" }
      '';
      extraConfig = "add_header Access-Control-Allow-Origin *;";
    };
  };
}
