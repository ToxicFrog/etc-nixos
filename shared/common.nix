# Common settings shared by all machines.

{ config, pkgs, lib, ... }:

let
  # Create a /dev/disk/by-wwn/ directory separate from /dev/disk/by-id
  # Fragments adapted from udev's persistent-storage.rules
  udevByWWN = ''
    ACTION=="remove", GOTO="by_wwn_end"
    SUBSYSTEM!="block", GOTO="by_wwn_end"
    KERNEL!="mmcblk*[0-9]|nvme*|sd*|sr*", GOTO="by_wwn_end"

    ENV{DEVTYPE}=="partition", ENV{.PART_SUFFIX}="-part%n"
    ENV{DEVTYPE}!="partition", ENV{.PART_SUFFIX}=""

    ENV{ID_WWN}=="0x*", SYMLINK+="disk/by-wwn/wwn-$env{ID_WWN}$env{.PART_SUFFIX}"
    ENV{ID_WWN}=="eui*", SYMLINK+="disk/by-wwn/$env{ID_WWN}$env{.PART_SUFFIX}"

    LABEL="by_wwn_end"
  '';
in {
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
  # This is a fairly grody hack to set the umask to 002 rather than 022 for all
  # user sessions, for use with user private groups (which are defined in
  # secrets/accounts.nix and secrets/users.nix).
  # The UMASK setting in loginDefs is read by pam_umask, but we need to enable
  # that.
  # There's no public escape hatch for doing so, but we can directly insert
  # entries into security.pam.services.*.rules.session to do so.
  security.loginDefs.settings.UMASK = "002";
  security.pam.services = lib.genAttrs ["login" "sshd" "su" "sudo"] (service: {
    rules.session.umask = {
      control = "optional";
      modulePath = "${config.security.pam.package}/lib/security/pam_umask.so";
      order = config.security.pam.services.${service}.rules.session.unix.order + 10;
    };
  });

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

  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.udev.extraRules = udevByWWN;
  boot.initrd.services.udev.rules = udevByWWN;
}
