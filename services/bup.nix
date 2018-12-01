# Ancilla backup services.

{ config, pkgs, ... }:

{
  systemd.timers.bup = {
    description = "Run daily backups";
    after = ["network.target" "local-fs.target"];
    wantedBy = ["multi-user.target"];
    timerConfig = {
      OnCalendar = "*-*-* 04:15:00";
      Unit = "bup.service";
    };
  };
  systemd.services.bup = {
    description = "Run daily backups";
    environment = {
      BUP_DIR = "/backup/bup-dir";
      BUPRC = "/backup/buprc.d";
    };
    path = with pkgs; [ bup git inetutils openssh ];
    serviceConfig.ExecStart = "${pkgs.bash}/bin/bash /backup/check-backups";
    serviceConfig.Type = "oneshot";
  };
}
