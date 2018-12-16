# Configuration for bittorrent daemons -- deluge and jackett.

{ config, pkgs, lib, ... }:

{
  users.extraUsers.deluge.home = lib.mkForce "/ancilla/torrents/deluge";
  systemd.services.deluged.requires = ["zfs-mount.service"];
  systemd.services.delugeweb.requires = ["deluged.service"];
  services = {
    deluge = {
      enable = true;
      web.enable = true;
    };

    jackett.enable = true;

    nginx.virtualHosts."ancilla.ancilla.ca".locations = {
      "/deluge/".extraConfig = ''
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_set_header        X-Deluge-Base "/deluge/";
        add_header              X-Frame-Options SAMEORIGIN;
        proxy_pass              http://127.0.0.1:8112/;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
      '';
      "/jackett/".extraConfig = ''
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_pass              http://127.0.0.1:9117;
        proxy_read_timeout      600s;
        proxy_send_timeout      600s;
      '';
    };
  };
}
