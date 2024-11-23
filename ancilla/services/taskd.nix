# Configuration for TaskWarrior server.
{ config, pkgs, lib, secrets, ... }:

{
  virtualisation.oci-containers.containers.taskwarrior-webui = {
    image = "dcsunset/taskwarrior-webui@sha256:cbd0af6cfe2ee6e8566c26e88566a1d5d09d124b552d6930841c5566029a5eec";
    ports = ["7360:80"];
    volumes = [
      "/home/bex/.task:/.task"
      "/home/bex/.taskrc:/.taskrc"
    ];
  };

  services.nginx.virtualHosts."task.ancilla.ca" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:7360$request_uri";
      proxyWebsockets = true;
      basicAuth = secrets.auth.nginx.ancilla;
    };
  };
}
