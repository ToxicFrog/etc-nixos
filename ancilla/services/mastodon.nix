# Configuration for Fediverse services, such as mastodon.
# Hosted on mastodon.ancilla.ca with @ancilla.ca usernames.
{ config, pkgs, lib, ... }:

let
  secrets = (import ../../secrets/default.nix {});
in {
  services.nginx = {
    clientMaxBodySize = "40M";
    commonHttpConfig = ''
      map $http_user_agent $nonempty_user_agent {
        ""   "Empty-User-Agent";
        default $http_user_agent;
      }
    '';
    virtualHosts."gts.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header User-Agent: $nonempty_user_agent;
        '';
      };
    };
  };
  # ancilla.ca is hosted offsite, so set up the redirects there
  # services.nginx.virtualHosts."ancilla.ca" = {
  #   locations."/.well-known/webfinger".return = "301 https://gts.ancilla.ca/.well-known/webfinger";
  #   locations."/.well-known/nodeinfo".return = "301 https://gts.ancilla.ca/.well-known/nodeinfo";
  # };

  users.users.gotosocial = {
    isSystemUser = true;
    description = "GoToSocial ActivityPub federated microblogging platform";
    home = "/var/lib/gts";
    createHome = true;
    group = "gotosocial";
    uid = 985;
  };
  users.groups.gotosocial = { gid = 978; };

  virtualisation.oci-containers.containers.gotosocial = {
    image = "superseriousbusiness/gotosocial@sha256:4b2bb2c0144a66477291eb6b75c27174dfa128517b81ce6ad21c8a7396fef12e";
    # uid and gid have to be hardcoded (here and above) because docker doesn't let us pass user by
    # name unless the same user/group exists inside the container.
    user = "985:978";
    ports = ["3000:8080"];
    volumes = [
      "/var/lib/gts:/gotosocial/storage"
    ];
    environment = {
      GTS_HOST = "gts.ancilla.ca";
      GTS_ACCOUNT_DOMAIN = "ancilla.ca";
      GTS_ACCOUNTS_REGISTRATION_OPEN = "false";
      GTS_DB_TYPE = "sqlite";
      GTS_DB_ADDRESS = "/gotosocial/storage/sqlite.db";
      GTS_LETSENCRYPT_ENABLED = "false";
    };
  };
}
