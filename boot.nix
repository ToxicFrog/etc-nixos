{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B77824F4828";
    };
    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["ancilla" "backup" "internal"];
    kernelParams = ["consoleblank=0"];
  };
  systemd.targets.zfs = {
    wantedBy = ["sysinit.target"];
    wants = ["zfs-mount.service"];
    before = ["local-fs.target" "multi-user.target" "sysinit.target" "network.target"];
  };
  systemd.services.zfs-mount.requires = ["zfs-import.target"];
}
