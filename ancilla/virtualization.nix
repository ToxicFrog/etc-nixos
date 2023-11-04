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
    # interfaces.br0.useDHCP = true;
    interfaces.br0 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.1.34"; prefixLength = 24; } ];
      ipv6.addresses = [ { address = "fd85:f753:480f::7b3"; prefixLength = 128; } ];
    };
    defaultGateway = { address = "192.168.1.1"; interface = "br0"; };
    nameservers = [ "192.168.1.1" ];
  };
  # We have to force this to run after br0 is created, or br0 never gets an
  # address :(
  systemd.services.dhcpcd.after = [ "br0-netdev.service" ];
  # none of these workarounds work; we have to manually `systemctl restart network-setup` after each major rebuild :(
}
