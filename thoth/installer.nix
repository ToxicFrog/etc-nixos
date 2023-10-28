# This module defines a small NixOS installation CD. It does not
# contain any graphical stuff.
{ config, pkgs, lib, unstable, inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  boot.supportedFilesystems = [ "bcachefs" "zfs" ];
  boot.kernelPackages = lib.mkOverride 0 unstable.linuxPackages_testing_bcachefs;
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  networking = {
    # use nmtui rather than wpa_supplicant
    wireless.enable = false;
    networkmanager.enable = true;
  };
  environment.systemPackages = with pkgs; [ keyutils ];
}
