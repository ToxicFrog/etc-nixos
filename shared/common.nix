# Common settings shared by all machines.

{ config, pkgs, lib, ... }:

{
  imports = [
    ./common-nix.nix
    ./common-services.nix
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

  time.timeZone = lib.mkDefault "America/Toronto";
  i18n = {
    defaultLocale = "en_CA.UTF-8";
    extraLocaleSettings.LC_TIME = "en_DK.UTF-8";
    supportedLocales = [ "all" ];
  };
}
