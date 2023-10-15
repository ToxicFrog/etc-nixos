# Virtualization settings.
# Enables dconf and libvirtd for virt-manager controlled VMs.
# Also configures a bridge network that VMs can attach to.
{ config, pkgs, lib, ... }:

{
  # virtualisation.docker.storageDriver = "overlay2"; # requires bleeding-edge zfs to function
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager virt-manager-qt ];
  virtualisation.libvirtd.enable = true;
  networking = {
     bridges.br0.interfaces = [ "enp27s0" ];
     interfaces.enp27s0.useDHCP = false;
     interfaces.br0.useDHCP = true;
     dhcpcd.extraConfig = ''
       interface br0

     '';
  };
}
