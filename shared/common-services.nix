# Common services that run on all machines, like locate and munin.

{ config, pkgs, lib, ... }:

{
  services = {
    locate = {
      enable = true;
      locate = pkgs.plocate;
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
          enable = false;
          # TODO we need a different mailer for this!
          # mailer = "/run/current-system/sw/bin/hugin";
          # recipient = "#ancilla";
        };
      };
    };
  };
}
