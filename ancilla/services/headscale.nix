# Configuration for Fediverse services, such as mastodon.
# Hosted on mastodon.ancilla.ca with @ancilla.ca usernames.
{ config, pkgs, lib, ... }:

{
  services.headscale = {
    enable = true;
    # address = "0.0.0.0";
    port = 8514;
    settings = {
      useRoutingFeatures = "server";
      dns = {
        base_domain = "tailnet.ancilla.ca";
        search_domains = [ "ancilla.ca" ];
        nameservers.global = [ "192.168.1.1" ];
        override_local_dns = true;
      };
      server_url = "https://headscale.ancilla.ca";
      # current version
      ip_prefixes = [
        "fd7a:115c:a1e0::/48"
        "100.64.0.0/10"
      ];
      # upcoming version
      prefixes = {
        v6 = "fd7a:115c:a1e0::/48";
        v4 = "100.64.0.0/10";
      };
    };
  };

  services.nginx.virtualHosts."headscale.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:8514/";
      proxyWebsockets = true;
    };
  };

  environment.systemPackages = [
    config.services.headscale.package
    config.services.tailscale.package
  ];

  # Set up an edge router
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--login-server=https://headscale.ancilla.ca"
      "--advertise-routes=192.168.1.0/24"
      "--advertise-exit-node"
      # "--exit-node-allow-lan-access"  # use this on the client, not the EN
    ];
  };
}
