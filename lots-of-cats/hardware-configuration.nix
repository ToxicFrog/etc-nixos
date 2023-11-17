{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd.availableKernelModules = [ "ahci" "ohci_pci" "ehci_pci" "xhci_pci" "firewire_ohci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    # efi.efiSysMountPoint = "/boot";
  };

  fileSystems."/" =
    { device = "/dev/disk/by-label/pladix-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/PLADIXBOOT";
      fsType = "vfat";
    };

  fileSystems."/ancilla" =
    { device = "ancilla:/ancilla";
      fsType = "nfs";
    };

  fileSystems."/home/alex" =
    { device = "alex@ancilla:/home/alex";
      fsType = "sshfs";
      options = [
        "reconnect" "default_permissions" "allow_other" "delay_connect"
        "uid=${toString config.users.users.alex.uid}"
        "gid=${toString config.users.groups.users.gid}"
        "ServerAliveInterval=15" "IdentityFile=/root/.ssh/alex.rsa"
      ];
    };

  swapDevices = [
    { device = "/dev/disk/by-label/pladix-swap"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
