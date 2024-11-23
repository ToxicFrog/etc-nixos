# Common settings shared by all machines.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./common-nix.nix
    ./common-services.nix  # TODO: disable this for the installer and isci-target builds
    ./common-packages.nix
    ./overlays.nix
  ];

  users = {
    mutableUsers = false;
    enforceIdUniqueness = false;
  };

  programs.zsh.enable = true;
  boot.tmp.cleanOnBoot = true;
  documentation.man.generateCaches = true;  # Enable whatis/apropos.
  security.pki.certificateFiles = [ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];

  # big CVE here! We can configure printers by hand.
  systemd.services.cups-browsed.enable = false;

  # JMicron USB/SATA HBA doesn't support UAS
  boot.extraModprobeConfig = ''
    options usb_storage quirks=152d:0565:u,2109:0711:u
  '';

  time.timeZone = lib.mkDefault "America/Toronto";
  i18n = {
    defaultLocale = "en_CA.UTF-8";
    extraLocaleSettings.LC_TIME = "en_DK.UTF-8";
    supportedLocales = [ "all" ];
  };

  hardware.enableRedistributableFirmware = true;
}
