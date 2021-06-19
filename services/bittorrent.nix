# Configuration for bittorrent daemons -- deluge and jackett.

{ config, pkgs, lib, ... }:

{
  users.extraUsers.deluge.home = lib.mkForce "/ancilla/torrents/deluge";
  users.extraUsers.deluge.createHome = lib.mkForce false;
  users.extraUsers.deluge.group = "deluge";
  users.groups.deluge.gid = 83;
  systemd.services.deluged.requires = ["zfs-mount.service"];
  systemd.services.transmission.requires = ["zfs-mount.service"];
  systemd.services.delugeweb.requires = ["deluged.service"];
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
  services = {
    transmission = {
      enable = false;
      group = "deluge";
      user = "deluge";
      home = "/ancilla/torrents/transmission";
      openFirewall = true;
      port = 9091;
      downloadDirPermissions = "775";
      settings = {
        download-dir = "/ancilla/torrents/complete";
        incomplete-dir = "/ancilla/torrents/buffer";
        watch-dir = "/ancilla/torrents/new";
        incomplete-dir-enabled = true;
        watch-dir-enabled = true;
        peer-port = 8010;
        peer-port-random-low = 8000;
        peer-port-random-high = 8050;
        peer-port-random-on-start = true;
        umask = 2;
        message-level = 2;
        # rpc-authentication-required = true;
        # rpc-password = "deluge";
        rpc-host-whitelist = "ancilla.ancilla.ca";
        rpc-host-whitelist-enabled = true;
      };
    };

    deluge = {
      enable = false;
      web.enable = false;
    };

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
      "/deluge/".extraConfig = ''
        proxy_set_header        X-Deluge-Base "/deluge/";
        add_header              X-Frame-Options SAMEORIGIN;
        proxy_pass              http://127.0.0.1:8112/;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
      '';
      "/transmission".extraConfig = ''
        proxy_pass http://127.0.0.1:9091;
        proxy_pass_header X-Transmission-Session-Id;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
      "/jackett/".extraConfig = ''
        proxy_pass              http://127.0.0.1:9117;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
      '';
    };
  };
}
