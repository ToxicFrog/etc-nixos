{ pkgs, lib, secrets, ... }:

let
  immich-version = "v1.84.0";
  digests = {
    immich-server = "sha256:0490190b13202546d8bcff5731dd98df8bc4aabc48f70b7aa737e77b99cfea04";
    immich-ml = "sha256:fac57d077110efd282abeaaf5ed16b3b9f0353fbcef7f6afc8a2fdad4382420e";
    immich-web = "sha256:e8d31d9a5cf3556c80817e96cb0136a46d7bd7e115ca30f4183e82fd9263420f";
    immich-proxy = "sha256:20fdcaab64166b42acd73dbe8ac0a1cff5082cd09619f8df535fb5dec0a544db";
  };

  photosLocation = "/ancilla/media/photos/immich";

  autoStart = false;
  extraOptions = [ "--network=immich-bridge" "--add-host=host.docker.internal:host-gateway" ];
  environment = {
    DB_HOSTNAME = "host.docker.internal";
    DB_USERNAME = "immich";
    DB_PASSWORD = secrets.immich.db-pass;
    DB_DATABASE_NAME = "immich";

    REDIS_HOSTNAME = "host.docker.internal";
    REDIS_PASSWORD = secrets.immich.redis-pass;

    TYPESENSE_ENABLED = "true";
    TYPESENSE_HOST = "immich-typesense";
    TYPESENSE_API_KEY = secrets.immich.typesense-key;
    TYPESENSE_DATA_DIR = "/data";

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

    ensureUsers = [
      {
        name = environment.DB_USERNAME;
        ensurePermissions = {
          "DATABASE ${environment.DB_DATABASE_NAME}" = "ALL PRIVILEGES";
          "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
        };
      }
    ];

    authentication = ''
      host immich immich 172.18.0.0/24 md5
    '';
  };

  virtualisation.oci-containers.containers = {
    immich-server = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-server:${immich-version}@${digests.immich-server}";
      entrypoint = "/bin/sh";
      cmd = [ "start.sh" "immich" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
      ];

      dependsOn = [ "immich-typesense" ];
    };

    immich-microservices = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-server:${immich-version}@${digests.immich-server}";
      entrypoint = "/bin/sh";
      cmd = [ "start.sh" "microservices" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
      ];

      dependsOn = [ "immich-typesense" ];
    };

    immich-ml = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-machine-learning:${immich-version}@${digests.immich-ml}";

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "/ancilla/media/photos:/ancilla/media/photos:ro"
        "model-cache:/cache"
      ];
    };

    immich-web = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-web:${immich-version}@${digests.immich-web}";
    };

    immich-proxy = {
      inherit autoStart extraOptions environment;
      image = "ghcr.io/immich-app/immich-proxy:${immich-version}@${digests.immich-proxy}";

      log-driver = "none";
      ports = [ "9137:8080" ];
      dependsOn = [ "immich-server" "immich-web" ];
    };

    immich-typesense = {
      inherit autoStart extraOptions environment;
      image = "typesense/typesense:0.24.1";

      volumes = [
        "tsdata:/data"
      ];

      log-driver = "none";
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
      proxyPass = "http://localhost:9137";
      proxyWebsockets = true;
      extraConfig = ''
        client_max_body_size 0;
        proxy_max_temp_file_size 96384m;
      '';
    };
  };
}
