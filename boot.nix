{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B77824F4828";
    };

    kernelParams = ["consoleblank=0"];
    kernelModules = [ "kvm-intel" ];

    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["ancilla" "backup" "internal"];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
    extraModulePackages = [ ];
  };
  systemd.targets.zfs = {
    wantedBy = ["sysinit.target"];
    wants = ["zfs-mount.service"];
    before = ["local-fs.target" "multi-user.target" "sysinit.target" "network.target"];
  };
  systemd.services.zfs-mount.requires = ["zfs-import.target"];
}
