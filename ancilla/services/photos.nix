{ pkgs, lib, secrets, ... }:

let
  immich-version = "v1.91.4";
  digests = {
    immich-server = "sha256:f1dd777fd38f30fc17a3dbe6a9f7dc9c548c41f9688908bf79d4109733e09b54";
    immich-ml = "sha256:634c4a66ea5c8a6e4679d7560d34abda67f88dc1d6adda18f56c00c58a07ac6d";
  };

  photosLocation = "/ancilla/media/photos/immich";

  autoStart = true;
  extraOptions = [ "--network=immich-bridge" "--add-host=host.docker.internal:host-gateway" ];
  environment = {
    DB_HOSTNAME = "host.docker.internal";
    DB_USERNAME = "immich";
    DB_PASSWORD = secrets.immich.db-pass;
    DB_DATABASE_NAME = "immich";

    REDIS_HOSTNAME = "host.docker.internal";
    REDIS_PASSWORD = secrets.immich.redis-pass;

    IMMICH_WEB_URL = "http://immich-web:3000";
    IMMICH_SERVER_URL = "http://immich-server:3001";
    IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
  };
in
{
  services.redis.servers.immich = {
    enable = true;
    openFirewall = true;
    port = 6379;
    requirePass = environment.REDIS_PASSWORD;
    bind = null;
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
  services.postgresql = {
    enableTCPIP = true;
    ensureDatabases = [ environment.DB_DATABASE_NAME ];
    extraPlugins = with pkgs; [ pgvecto-rs ];
    settings = { shared_preload_libraries = "vectors.so"; };

    ensureUsers = [
      {
        name = environment.DB_USERNAME;
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
    ];

    authentication = ''
      host immich immich 172.18.0.0/24 md5
    '';
  };

  virtualisation.oci-containers.containers = {
    immich-server = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-server:${immich-version}";#@${digests.immich-server}";
      entrypoint = "/bin/sh";
      cmd = [ "start.sh" "immich" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
      ];

      ports = [ "3001:3001" ];
    };

    immich-microservices = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-server:${immich-version}";#@${digests.immich-server}";
      entrypoint = "/bin/sh";
      cmd = [ "start.sh" "microservices" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
      ];
    };

    immich-ml = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-machine-learning:${immich-version}";#@${digests.immich-ml}";

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
        "model-cache:/cache"
      ];
    };
  };

  systemd.services.init-immich-network = {
    description = "Create the network bridge for immich.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      check=$(${pkgs.docker}/bin/docker network ls | grep "immich-bridge" || true)
      if [ -z "$check" ];
        then ${pkgs.docker}/bin/docker network create immich-bridge
        else echo "immich-bridge already exists in docker"
      fi
      '';
  };

  services.nginx.virtualHosts."photos.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:3001";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 0;
        proxy_max_temp_file_size 96384m;
      '';
    };
  };
}
