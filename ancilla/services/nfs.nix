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
      # /ancilla/installs/games pladix.ancilla.ca(ro,all_squash,anonuid=1000,anongid=100)
      # /ancilla/installs/games/Retroarch pladix.ancilla.ca(rw,all_squash,anonuid=1000,anongid=100)
      # /ancilla/installs/games/DOS pladix.ancilla.ca(rw,all_squash,anonuid=1000,anongid=100)
      # /ancilla/media (ro,all_squash,anonuid=1000,anongid=100)
      # *.ancilla.ca doesn't work reliably with machines that connect from both wifi and ethernet
      # e.g. with pladix, dig returns the wifi address but it connects over ethernet
      # TODO: fix this
      #/ancilla          *.ancilla.ca(rw,crossmnt,no_subtree_check,root_squash,anongid=${toString config.users.groups.users.gid})
      /ancilla          192.168.1.0/24(rw,crossmnt,no_subtree_check,root_squash,anongid=${toString config.users.groups.users.gid})
      /home/alex        192.168.1.0/24(rw,crossmnt,no_subtree_check,root_squash,anongid=${toString config.users.groups.users.gid})
    '';
      # /ancilla/installs 192.168.86.0/24(rw,crossmnt,no_subtree_check)
      # /ancilla/media
      # /home      192.168.86.0/24(rw,crossmnt,no_subtree_check)
  };
}
