# NFS network drive configuration

{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 4002 ];
  networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 ];
  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    exports = ''
      /ancilla/installs/games/Retroarch pladix.ancilla.ca(rw,all_squash,anonuid=1000,anongid=100)
    '';
      # /ancilla          192.168.86.0/24(rw,crossmnt,no_subtree_check)
      # /ancilla/installs 192.168.86.0/24(rw,crossmnt,no_subtree_check)
      # /ancilla/media
      # /home      192.168.86.0/24(rw,crossmnt,no_subtree_check)
  };
}
