# Common services that run on all machines, like locate and munin.

{ config, pkgs, lib, ... }:

let
  # We need to publish to hugin/smartd/<hostname>
  # We send a multiline string payload; our "subject" is the first line
  # cat /tmp/smartd-notify-653220 | egrep '^(Subject|Device|Model Family|Device Model|Serial Number|User Capacity):'
  # Subject: SMART error (OfflineUncorrectableSector) detected on host: ancilla
  # Device: /dev/sdg [USB Prolific], 2 Offline uncorrectable sectors
  # Model Family:     Western Digital Red
  # Device Model:     WDC WD20EFRX-68AX9N0
  # Serial Number:    WD-WMC301428176
  # User Capacity:    2,000,398,934,016 bytes [2.00 TB]
  smartd-notify = pkgs.writeShellScript "smartd-notify" ''
    ${pkgs.gnugrep}/bin/egrep \
      '^(Subject|Device|Model Family|Device Model|Serial Number|User Capacity):' \
    | ${pkgs.gnused}/bin/sed -E 's,Subject: +,,; s,  +, ,g;' \
    | ${pkgs.jq}/bin/jq -R -s . \
    | ${pkgs.mosquitto}/bin/mosquitto_pub -L mqtt://ancilla.ancilla.ca/hugin/smartd/$(hostname) -s
  '';
in {
  networking.firewall.allowedTCPPorts = [ 4949 ];  # munin-node
  services = {
    fstrim.enable = true;

    kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        { name = "Cousine Nerd Font Mono"; package = (pkgs.nerdfonts.override { fonts = [ "Cousine" ]; }); }
      ];
    };

    locate = {
      enable = true;
      package = pkgs.plocate;
      localuser = null;  # plocate always runs as root
    };

    munin-node = {
      enable = true;
      extraConfig = ''
        cidr_allow 192.168.1.0/24
        cidr_allow fd85:f753:480f::/48
      '';
    };

    openssh = {
      enable = true;
      ports = lib.mkDefault [ 22 ];
      settings.X11Forwarding = true;
      allowSFTP = true;
    };

    printing = {
      enable = true;
      drivers = with pkgs; [ samsung-unified-linux-driver samsung-unified-linux-driver_1_00_37 ];
    };

    smartd = {
      enable = true;
      # Automatically monitor devices
      # Do not probe disks on standby unless they've skipped the last 24 probes
      # Enable automatic offline data collection
      # Run a short self-test every morning at 5am
      # Report if new errors appear in the selftest or error logs
      defaults.autodetected = "-a -n standby,24 -o on -s (S/../.././05) -l error -l selftest";
      notifications = {
        test = false;
        wall.enable = true;
        x11.enable = true;
        mail = {
          enable = true;
          mailer = "${smartd-notify}";
          recipient = "hugin/smartd";
          # TODO we need a different mailer for this!
          # mailer = "/run/current-system/sw/bin/hugin";
          # recipient = "#ancilla";
        };
      };
    };
  };
}
