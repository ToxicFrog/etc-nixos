{ config, pkgs, lib, unstable, inputs, ... }:
{
  imports = [
    "${inputs.nixos}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
  ];
  # boot.supportedFilesystems = [ "bcachefs" "zfs" ];
  # boot.kernelPackages = lib.mkOverride 0 unstable.linuxPackages_testing_bcachefs;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  networking = {
    # use nmtui rather than wpa_supplicant
    wireless.enable = false;
    networkmanager.enable = true;
  };
  environment.systemPackages = with pkgs; [ keyutils ];
}
