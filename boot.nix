{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/disk/by-id/usb-Generic-_SD_MMC_20090815198100000-0:0";
    };
    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["ancilla" "backup" "nix"];
    kernelParams = ["consoleblank=0"];
  };
  systemd.targets.zfs = {
    wantedBy = ["local-fs.target" "multi-user.target" "sysinit.target"];
    wants = ["zfs-mount.service"];
    before = ["local-fs.target" "multi-user.target" "sysinit.target"];
  };
  systemd.services.zfs-mount.requires = ["zfs-import.target"];
}
