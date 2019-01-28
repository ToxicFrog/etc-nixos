{ config, pkgs, ... }:

{
  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      version = 2;
      device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B77824F4828";
    };
    # loader.systemd-boot.enable = true;
    # loader.efi.canTouchEfiVariables = true;

    kernelParams = ["consoleblank=0"];
    kernelModules = ["k10temp" "nct6775"];

    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["ancilla" "backup" "internal"];
    zfs.devNodes = "/dev/disk/by-path";
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
    extraModulePackages = [ ];

    postBootCommands = ''
      ls /srv /ancilla
      zpool import -a -d -N /dev/disk/by-path
      zfs mount -a
      ls /srv /ancilla
    '';
  };
  # systemd.targets.zfs = {
  #   wantedBy = ["sysinit.target"];
  #   wants = ["zfs-mount.service"];
  #   before = ["local-fs.target" "multi-user.target" "sysinit.target" "network.target"];
  # };
  # systemd.services.zfs-mount.requires = ["zfs-import.target"];
  # systemd.services.zfs-zed = {
  #   after = ["zfs-mount.service"];
  #   unitConfig = {
  #     DefaultDependencies = false;
  #   };
  # };
  # systemd.services.zfs-share = {
  #   after = ["zfs-mount.service"];
  #   unitConfig = {
  #     DefaultDependencies = false;
  #   };
  # };
}
