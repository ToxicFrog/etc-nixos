{ config, lib, pkgs, ... }:

{
  # Minecraft server port.
  networking.firewall.allowedTCPPorts = [25565];

  # Dynmap reverse proxy.
  services.nginx.virtualHosts."minecraft.ancilla.ca".locations."/".extraConfig = ''
    proxy_pass http://127.0.0.1:8123/;
    auth_basic off;
  '';

  # Minecraft user.
  users.users.minecraft = {
    isSystemUser = true;
    description = "Minecraft server user";
    home = "/srv/minecraft";
    group = "minecraft";
  };
  users.groups.minecraft = {};

  # Minecraft server process.
  systemd.services.minecraft-server = {
    description = "Minecraft Server";
    after = [ "network.target" ];
    wantedBy = []; #[ "multi-user.target" ];
    enable = false;
    serviceConfig = {
      User = "minecraft";
      Group = "minecraft";
      Restart = "no";
      WorkingDirectory = "/srv/minecraft";
      # ExecStart = "${pkgs.jdk}/bin/java -Xms512M -Xmx1G -XX:+UseConcMarkSweepGC -jar spigot-1.16.1.jar";
      ExecStart = "${pkgs.jdk11_headless}/bin/java -Xms512M -Xmx2G -jar paper.jar --universe worlds/";
    };
  };
}
