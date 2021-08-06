{ config, pkgs, lib, ... }:

let
  unstable = (import <nixos-unstable> { config.allowUnfree = true; });
in {
  # imports = [ <nixos-unstable/nixos/modules/services/misc/dendrite.nix> ];

  # services.dendrite.enable = true;
  users.users.matrix = {
    isSystemUser = true;
    description = "Matrix server";
    home = "/srv/matrix";
  };

  services.nginx.virtualHosts."matrix.ancilla.ca" = {
    enableACME = true;
    forceSSL = true;
    locations."/_matrix/".proxyPass = "http://127.0.0.1:6167$request_uri";
  };

  systemd.services.matrix-conduit = {
    description = "Conduit Matrix server";
    after = [ "network.target" ];
    wantedBy = [];
    enable = true;
    restartTriggers = ["/etc/matrix.conduit.toml"];
    environment = {
      CONDUIT_CONFIG = "/etc/matrix/conduit.toml";
    };
    serviceConfig = {
      User = "matrix";
      Group = "nogroup";
      Restart = "no";
      WorkingDirectory = "/srv/matrix";
      ExecStart = "/srv/matrix/conduit-bin";
    };
  };

  # N.b. we're hosting at matrix.ancilla.ca, but our server_name is ancilla.ca
  # this means that https://ancilla.ca/.well-known/matrix/{client,server} needs
  # to exist and contain JSON:
  #### client
  # {
  # "m.homeserver": {
  #   "base_url": "https://matrix.ancilla.ca"
  # },
  # }
  #### server
  # {
  #   "m.server": "matrix.ancilla.ca:443"
  # }


  environment.etc."matrix/conduit.toml".text = ''
    [global]
    # The server_name is the name of this server. It is used as a suffix for user
    # and room ids. Examples: matrix.org, conduit.rs
    # The Conduit server needs to be reachable at https://your.server.name/ on port
    # 443 (client-server) and 8448 (federation) OR you can create /.well-known
    # files to redirect requests. See
    # https://matrix.org/docs/spec/client_server/latest#get-well-known-matrix-client
    # and https://matrix.org/docs/spec/server_server/r0.1.4#get-well-known-matrix-server
    # for more information

    server_name = "ancilla.ca"

    # This is the only directory where Conduit will save its data
    database_path = "/srv/matrix/conduit-db"

    # The port Conduit will be running on. You need to set up a reverse proxy in
    # your web server (e.g. apache or nginx), so all requests to /_matrix on port
    # 443 and 8448 will be forwarded to the Conduit instance running on this port
    port = 6167

    # Max size for uploads
    max_request_size = 20_000_000 # in bytes

    # Disabling registration means no new users will be able to register on this server
    allow_registration = false

    # Disable encryption, so no new encrypted rooms can be created
    # Note: existing rooms will continue to work
    allow_encryption = true
    allow_federation = true

    trusted_servers = ["matrix.org"]

    #cache_capacity = 1073741824 # in bytes, 1024 * 1024 * 1024
    #max_concurrent_requests = 100 # How many requests Conduit sends to other servers at the same time
    #workers = 4 # default: cpu core count * 2

    address = "127.0.0.1" # This makes sure Conduit can only be reached using the reverse proxy
  '';
}
