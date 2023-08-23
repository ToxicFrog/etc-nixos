{ config, pkgs, lib, ... }:

{
  systemd.defaultUnit = lib.mkForce "multi-user.target";
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
      # device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B77824F4828";
      zfsSupport = true;
      mirroredBoots = [
        { path = "/boot"; devices = ["/dev/disk/by-id/ata-WDC_WDS500G2B0B_184220A01A66"]; }
        { path = "/alt-boot"; devices = ["/dev/disk/by-id/nvme-WUS3BA138C7P3E3_A06F1084"]; }
      ];
      splashImage = /ancilla/media/photos/DigiKam/Avatars/triop-rainbow-720x720.png;
    };
    # loader.systemd-boot.enable = true;
    # loader.efi.canTouchEfiVariables = true;

    kernelParams = ["consoleblank=0" "nohibernate"];
    kernelModules = ["k10temp" "nct6775" "netatop"];

    supportedFilesystems = ["zfs"];
    #zfs.extraPools = ["ancilla" "backup" "internal"];
    zfs.devNodes = "/dev/disk/by-path";
    zfs.forceImportRoot = false;
    initrd.kernelModules = [ "nvme" ];
    initrd.availableKernelModules = [
      "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc"
    ];
    extraModulePackages = [ pkgs.linuxPackages.netatop ];

    postBootCommands = ''
      echo "=== STARTING ZPOOL IMPORT ==="
      # Clean up borg-repo because the activation script creates it
      ${pkgs.findutils}/bin/find /backup/borg-repo -maxdepth 1 -type d -empty -delete
      ${pkgs.findutils}/bin/find /srv -maxdepth 1 -type d -empty -delete
      ${pkgs.zfs}/bin/zpool import -a -N -d /dev/disk/by-path
      ${pkgs.zfs}/bin/zpool status
      ${pkgs.zfs}/bin/zfs mount -a
      echo "=== ZPOOL IMPORT COMPLETE ==="
      # Enable compressed RAM.
      echo Y > /sys/module/zswap/parameters/enabled
    '';
  };
}
