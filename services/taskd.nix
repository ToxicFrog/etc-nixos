# Configuration for TaskWarrior server.
{ config, pkgs, lib, ... }:

{
  services.taskserver = {
    enable = true;
    openFirewall = true;
    organisations."ancilla.ca".users = [ "bex" ];
    listenHost = "::";
    fqdn = "task.ancilla.ca";
  };
}
