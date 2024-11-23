{ config, pkgs, lib, unstable, inputs, ... }:
{
  imports = [
    "${inputs.nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  # boot.kernelParams = [ "live.nixos.password=nixos" ];
  networking = {
    hostName = "scuzzbucket";
    domain = "ancilla.ca";
    firewall.enable = false;
    wireless.enable = false;
    useDHCP = true;
  };
  services.target.enable = true;
  services.printing.enable = lib.mkForce false;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.password = "scsi";
  users.users.nixos.password = "scsi";
}
