# Virtualization settings.
# Enables dconf and libvirtd for virt-manager controlled VMs.
# Also configures a bridge network that VMs can attach to.
{ config, pkgs, lib, ... }:

{
  virtualisation.docker.storageDriver = "overlay2";
}
