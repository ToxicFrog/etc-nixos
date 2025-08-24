# NFS network drive configuration

{ config, pkgs, lib, ... }:

let
  concatStringsSep = lib.strings.concatStringsSep;
  common_opts = ["crossmnt" "no_subtree_check" "root_squash" "anongid=${toString config.users.groups.users.gid}"];
  ro_opts = common_opts ++ ["ro"];
  rw_opts = common_opts ++ ["rw"];
  exports = [
    { path = "/ancilla"; hosts = ["pladix" "durandal"]; opts = rw_opts; }
    { path = "/home/alex"; hosts = ["pladix"]; opts = rw_opts; }
    { path = "/backup/hass"; hosts = ["station"]; opts = rw_opts; }
    { path = "/backup/nfs/pve"; hosts = ["katamari"];
      opts = ["rw" "no_root_squash" "no_subtree_check"]; }
    { path = "/backup/nfs/nwf"; hosts = ["nwf-vm"];
      opts = [ "crossmnt" "no_subtree_check" "no_root_squash" "rw" ]; }
    # { path = "/home/nwf"; hosts = ["nwf-vm"];
    #   opts = [ "crossmnt" "no_subtree_check" "no_root_squash" "rw" ]; }
    { path = "/ancilla/installs"; hosts = ["nwf-vm"]; opts = ro_opts; }
    { path = "/ancilla/media"; hosts = ["nwf-vm"]; opts = ro_opts; }
  ];
  mkexport =
    export: let
      opts = (concatStringsSep "," export.opts);
      hosts = (concatStringsSep " " export.hosts);
    in "${export.path} -${opts} ${hosts}";
in {
  networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 4002 ];
  networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 ];
  services.nfs.server = {
    enable = true;
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    exports = (concatStringsSep "\n" (map mkexport exports));
  };
}
