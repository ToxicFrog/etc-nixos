# Ancilla services not large enough to need their own file.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  imports = [
    ../munin/munin.nix
    ../munin/hugin.nix
    ../secrets/personal-services.nix
    ./bitburner.nix
    ./bittorrent.nix
    ./borgbackup.nix
    ./kanboard.nix
    ./library.nix
    ./minecraft.nix
    ./music.nix
    ./plex.nix
    ./nfs.nix
    ./nginx.nix
    ./smb.nix
    ./tv.nix
  ];

  users.users.git.createHome = lib.mkForce false;
  systemd.services.gitolite-init.after = ["local-fs.target"];

  services = {
    keybase.enable = true;
    kbfs.enable = true;
    # crossfire-server = {
    #   enable = false;
    #   openFirewall = true;
    #   etc.settings = ''
    #     balanced_stat_loss true
    #   '';
    #   etc.dm_file = secrets.crossfire-dmfile;
    #   package = pkgs.crossfire-server-latest;
    # };
    # deliantra-server = {
    #   enable = false;
    #   openFirewall = true;
    #   config = ''
    #     checkrusage: { vmsize: 2147483648 }
    #     map_max_reset: 604800
    #     map_default_reset: 86400
    #   '';
    # };

    fail2ban = {
      enable = true;
      ignoreIP = ["192.168.86.0/24"];
    };

    apcupsd = {
      enable = true;
      configText = ''
        UPSTYPE usb
        NISIP 127.0.0.1
        BATTERYLEVEL 10
        MINUTES 5
      '';
    };
    bitlbee = {
      enable = true;
      plugins = with pkgs; [ bitlbee-facebook bitlbee-steam ];
      # libpurple_plugins = with pkgs; [ purple-hangouts ];
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
        mail = {
          enable = true;
          mailer = "/run/current-system/sw/bin/hugin";
          recipient = "#ancilla";
        };
      };
    };

    # Gitolite git repo hosting (mostly used by Nightstar)
    gitolite = {
      enable = true;
      dataDir = "/srv/git";
      user = "git";
      adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8yJCgbZVMxI5mfzhRqPl5aP3yEksIrzCAf8IdoM38mxJRyu8fFxOu2iRiNHSUAWvFMvsslhs59DKMMoAdNy2qTIglpt4HAKM5TahYt88UmewbdEniLF3MhUlNwa0rAzFwB4V/X++0kBb5AmAYpESibGqPnpHqPMeMZeJHCP21GjhSduhS/rtdVv9wgm7Ng6Ezsh4Bxo/hPO9T4RmhMGV0V6JyFePBzQpvfWXlgiAWVpkRntFY3Io6+m3l0PBafqe+a2du6C+CgFgBUqBoOwM4kDBON2t6dpyQ+DxnLYLfMMv+sAer+Ko+mrZG6NyzoyZH6kPLwP5Jt68KtBpsHBfKw== bk@ancilla";
    };

    # Disable systemd-level power management.
    logind.extraConfig =
      "HandleLidSwitch=ignore"
        + "\nHandleSuspendKey=ignore"
        + "\nHandleHibernateKey=ignore"
        + "\nHandlePowerKey=ignore";

    tlp.enable = true;
    locate = {
      enable = true;
      localuser = "root";
      extraFlags = ["--dbformat=slocate"];
    };

    openssh = {
      enable = true;
      forwardX11 = true;
      allowSFTP = true;
      # permitRootLogin = "yes";
    };
  };

  # Crank the inotify limit waaaaay up there for syncthing.
  boot.kernel.sysctl = { "fs.inotify.max_user_watches" = 204800; };

  # dyndns
  systemd.timers.dyndns = {
    description = "Update afraid.org DNS records (timer)";
    after = ["network.target" "local-fs.target"];
    wantedBy = ["multi-user.target"];
    timerConfig = {
      #OnCalendar = "*:0/15:*";
      OnBootSec = "15min";
      OnUnitActiveSec = "15min";
      Unit = "dyndns.service";
    };
  };
  systemd.services.dyndns = {
    description = "Update afraid.org DNS records (service)";
    serviceConfig.ExecStart = "${pkgs.curl}/bin/curl ${secrets.dyndns-url}";
    serviceConfig.Type = "oneshot";
  };
}
