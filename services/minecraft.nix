{ config, lib, pkgs, ... }:

{
  # Minecraft server port.
  networking.firewall.allowedTCPPorts = [25565];

  # Dynmap reverse proxy.
  services.nginx.virtualHosts."ancilla.ancilla.ca".locations."/maps/".extraConfig = ''
    proxy_pass http://127.0.0.1:8123/;
    auth_basic off;
  '';

  # Minecraft user.
  users.users.minecraft = {
    isSystemUser = true;
    description = "Minecraft server user";
    home = "/srv/minecraft";
  };

  # Minecraft server process.
  systemd.services.minecraft-server = {
    description = "Minecraft Server";
    after = [ "network.target" ];
    wantedBy = []; #[ "multi-user.target" ];
    enable = true;
    serviceConfig = {
      User = "minecraft";
      Group = "nogroup";
      Restart = "no";
      WorkingDirectory = "/srv/minecraft";
      ExecStart = "${pkgs.jdk}/bin/java -Xms512M -Xmx1G -XX:+UseConcMarkSweepGC -jar spigot-1.11.2.jar";
    };
  };
}
