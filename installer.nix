{ config, pkgs, lib, unstable, inputs, ... }:
{
  imports = [
    # "${inputs.nixos}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
    "${inputs.nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  # boot.supportedFilesystems = [ "bcachefs" "zfs" ];
  # boot.kernelPackages = lib.mkOverride 0 unstable.linuxPackages_testing_bcachefs;
  # isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  networking = {
    hostName = "nixos-installer";
    domain = "ancilla.ca";
    firewall.enable = false;
    wireless.enable = false;
    useDHCP = true;
  };
  environment.systemPackages = with pkgs; [ keyutils ];
  services.printing.enable = lib.mkForce false;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.password = "nixos";
  users.users.nixos.password = "nixos";
}
