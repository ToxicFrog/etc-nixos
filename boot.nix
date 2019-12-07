{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      version = 2;
      device = "nodev";
      # device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B77824F4828";
    };
    # loader.systemd-boot.enable = true;
    # loader.efi.canTouchEfiVariables = true;

    kernelParams = ["consoleblank=0"];
    kernelModules = ["k10temp" "nct6775" "netatop"];

    supportedFilesystems = ["zfs"];
    #zfs.extraPools = ["ancilla" "backup" "internal"];
    zfs.devNodes = "/dev/disk/by-path";
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
    extraModulePackages = [ pkgs.linuxPackages.netatop ];

    postBootCommands = ''
      echo "=== STARTING ZPOOL IMPORT ==="
      # Clean up borg-repo because the activation script creates it
      ${pkgs.findutils}/bin/find /backup/borg-repo -maxdepth 1 -type d -empty -delete
      ${pkgs.zfs}/bin/zpool import -a -N -d /dev/disk/by-path
      ${pkgs.zfs}/bin/zpool status
      ${pkgs.zfs}/bin/zfs mount -a
      echo "=== ZPOOL IMPORT COMPLETE ==="
    '';
  };
}
