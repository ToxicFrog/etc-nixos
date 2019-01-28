# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

let
  zfs = dataset: { device = dataset; fsType = "zfs"; };
in {
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./secrets/homedirs.nix
  ];

  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01 01:15:00";
  };

  fileSystems."/" = zfs "ancilla/root";
  fileSystems."/nix" = zfs "internal/nix";

  # also, check this out:
  # https://github.com/cleverca22/nixos-configs/blob/master/rescue_boot.nix
  # adds a boot menu entry that boots right into the NixOS installer, suitable
  # as a rescue system with more capability (probably) than the initrd.

  # This is pretty gross.
  # NixOS is unaware of ZFS mountpoints, and despite my best efforts, will try
  # to create various home directories/start services/etc before `zfs mount -a`
  # runs.
  # So, we list all the filesystems that could potentially interfere with that
  # here, and with any luck that means systemd will force them to be mounted
  # first.
  # Hopefully `zfs mount -a` will take care of the rest at a later stage of
  # boot.
  # Individual homedirs are in secrets/homedirs.nix.
  fileSystems."/home" = zfs "ancilla/home";
  fileSystems."/ancilla" = zfs "ancilla";
  fileSystems."/srv" = zfs "ancilla/srv";
  fileSystems."/ancilla/torrents" = zfs "backup/torrents";

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-label/m2-swap"; }
  ];

  nix.maxJobs = lib.mkDefault 4;
}
