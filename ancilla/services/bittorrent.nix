# Configuration for bittorrent daemons -- qbittorrentd and jackett.

{ config, pkgs, lib, unstable, ... }:

{
  users.extraGroups.deluge.gid = 83;
  users.extraUsers.deluge = {
    home = lib.mkForce "/ancilla/torrents/deluge";
    createHome = lib.mkForce false;
    group = "deluge";
    isSystemUser = true;
  };

  systemd.services.qbittorrentd = {
    description = "QBittorrent daemon";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    requires = ["zfs-mount.service"];
    script = ''
      ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox
    '';
    serviceConfig = {
      User = "deluge";
      Group = "deluge";
      WorkingDirectory = "~";
      Restart = "always";
      RestartSec = "5";
    };
  };

  networking.firewall.allowedTCPPortRanges = [
    { from = 8000; to = 8050; }
  ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 8000; to = 8050; }
  ];
  # local peer discovery
  networking.firewall.allowedTCPPorts = [6771];
  networking.firewall.allowedUDPPorts = [6771];

  services.jackett = {
    enable = true;
    package = unstable.jackett;
  };

  services.nginx.virtualHosts."ancilla.ancilla.ca".locations = {
    "/qbt/".extraConfig = ''
      proxy_pass              http://127.0.0.1:9091/;
      add_header              X-Frame-Options SAMEORIGIN;
      proxy_set_header        X-Forwarded-Host $http_host;
      proxy_read_timeout      600s;
      proxy_send_timeout      600s;
      http2_push_preload      on;
    '';
    "/jackett/".extraConfig = ''
      proxy_pass              http://127.0.0.1:9117;
      proxy_read_timeout      600s;
      proxy_send_timeout      600s;
    '';
  };
}
