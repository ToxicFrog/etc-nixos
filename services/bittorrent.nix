# Configuration for bittorrent daemons -- deluge and jackett.

{ config, pkgs, lib, ... }:

{
  users.extraUsers.deluge.home = lib.mkForce "/ancilla/torrents/deluge";
  users.extraUsers.deluge.createHome = lib.mkForce false;
  users.extraUsers.deluge.group = "deluge";
  users.groups.deluge.gid = 83;
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

  # environment.systemPackages = with pkgs; [ transmission ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 8000; to = 8050; }
  ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 8000; to = 8050; }
  ];

    jackett.enable = true;

    nginx.virtualHosts."ancilla.ancilla.ca".locations = {
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
  };
}
