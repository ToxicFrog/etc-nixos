{ config, pkgs, lib, unstable, ... }:

let
  version = "a126a36249df7fda1d89f345a34607e9e54a077a";
  src = pkgs.fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = version;
    hash = "sha256-YJQZYdty+t8rnSgtxzUmUtOV21hDdrjOzR6Q0cmJHVU=";
  };
  mautrix-discord-head = unstable.mautrix-discord.override {
    buildGoModule = args: pkgs.buildGoModule (args // {
      inherit src version;
      vendorHash = "sha256-AmAKSq3Nh+XMcR4g2Upt1d+v4kno0ESajiFybzW7coo=";
    });
  };
in
{
  services.matrix-conduit = {
    enable = true;
    extraEnvironment = {
      RUST_MIN_STACK = "16777216";
    };
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
      database_backend = "rocksdb";
      # log = "debug";
    };
  };
  systemd.services.conduit.serviceConfig.ReadWritePaths = "/srv/matrix-conduit/";
  systemd.services.conduit.after = [ "network-online.service" ];

  systemd.services.matrix2051 = {
    description = "Matrix2051 IRC gateway for Matrix";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target" "conduit.service" "mautrix-discord.service" "mautrix-googlechat.service"];
    after = ["network-online.target" "local-fs.target" "conduit.service" "mautrix-discord.service" "mautrix-googlechat.service"];
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
    wants = ["network-online.target" "conduit.service"];
    after = ["network-online.target" "local-fs.target" "conduit.service"];
    path = with pkgs; [ lottieconverter ];
    serviceConfig = {
      DynamicUser = "true";
      ExecStart = "${mautrix-discord-head}/bin/mautrix-discord";
      Restart = "on-failure";
      RestartSec = "30s";
      StateDirectory = "mautrix-discord";
      User = "mautrix-discord";
      WorkingDirectory = "/var/lib/mautrix-discord";
    };
  };

  # The gchat bridge depends on the python cgi module, which is deprecated, and
  # removed entirely in python3.13. For now we just use python3.12 for it, but
  # at some point we should add python3Packages.cgi-legacy to its closure as
  # an explicit dependency.
  systemd.services.mautrix-googlechat = let
    mautrix-googlechat = unstable.mautrix-googlechat.override { python3 = unstable.python312; };
    #unstable.mautrix-googlechat.overrideAttrs (old: {
    #  propagatedBuildInputs = old.propagatedBuildInputs ++ python3.pkgs.standard-cgi
    #})
  in {
    description = "Matrix-to-Googlechat puppeting bridge";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target" "conduit.service"];
    after = ["network-online.target" "local-fs.target" "conduit.service"];
    path = with pkgs; [ lottieconverter ];
    serviceConfig = {
      DynamicUser = "true";
      ExecStart = "${mautrix-googlechat}/bin/mautrix-googlechat";
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
