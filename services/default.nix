# Ancilla services not large enough to need their own file.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
  unstable = (import <nixos-unstable> {});
  localpkgs = (import /home/rebecca/devel/nixpkgs {});
in {
  imports = [
    <nixos-unstable/nixos/modules/services/misc/atuin.nix>
    ../munin/munin.nix
    ../munin/hugin.nix
    ../secrets/personal-services.nix
    ./bittorrent.nix
    ./borgbackup.nix
    # ./kanboard.nix
    ./library.nix
    ./mastodon.nix
    ./matrix.nix
    ./minecraft.nix
    ./music.nix
    ./nfs.nix
    ./nginx.nix
    ./smb.nix
    ./taskd.nix
    ./timelapse.nix
    ./tv.nix
    ./vncdesktop.nix
  ];

  users.users.git.createHome = lib.mkForce false;
  systemd.services.gitolite-init.after = ["local-fs.target"];

  # CUPS
  networking.firewall.allowedTCPPorts = [ 21 631 ];

  services = {
    # A'Tuin shell history synchronization
    atuin = {
      enable = true;
      openRegistration = false;
      port = 28034; # Unicode for TURTLE is 0x128034
    };
    postgresql.package = pkgs.postgresql_15;
    postgresql.ensureUsers = [{
        name = "atuin";
        ensurePermissions = {
          "DATABASE atuin" = "ALL PRIVILEGES";
          "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
        };
    }];
    nginx.virtualHosts."atuin.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:28034/";
      };
    };

    avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };

    printing = {
      allowFrom = ["all"];
      browsing = true;
      defaultShared = true;
      drivers = with pkgs; [ samsung-unified-linux-driver_1_00_37 ];
      enable = true;
      listenAddresses = ["*:631"];
    };

    keybase.enable = false;
    kbfs.enable = false;

    crossfire-server = {
      enable = false;
      openFirewall = true;
      configFiles = {
        settings = ''
          # Reduce stats with depletion on death rather than editing the character sheet.
          stat_loss_on_death false
          # Penalize newbies less and experienced players more.
          balanced_stat_loss true
          # Persist temp maps across runs.
          #recycle_tmp_maps true
          # Show HP bars for damaged entities.
          always_show_hp damaged
        '';
        news = ''
          %Welcome to the ancilla crossfire server!
          This server runs CF trunk, sometimes with local bugfixes. It also has a long map reset time (1 week).
          It is still under construction and created characters will often be [u]deleted without warning[/u] while the server is still being set up. Don't get too attached!

          %Current test items
          Extended spellbook names
          Spell/skill descriptions in spellbooks/scrolls/wands/etc
        '';
        dm_file = secrets.crossfire-dmfile;
      };
    };

    # deliantra-server = {
    #   enable = true;
    #   openFirewall = true;
    #   configFiles.config = ''
    #     checkrusage: { vmsize: 2147483648 }
    #     map_max_reset: 604800
    #     map_default_reset: 86400
    #   '';
    #   package = localpkgs.deliantra-server;
    #   dataDir = "${localpkgs.deliantra-data}";
    # };

    etcd.enable = true;
    etcd.dataDir = "/srv/etcd";

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
      plugins = with pkgs; [ bitlbee-mastodon bitlbee-facebook ];
      # plugins = with pkgs; [ unstable.bitlbee-facebook unstable.bitlbee-steam ];
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
      locate = pkgs.plocate;
      # localuser = "root";
      localuser = null
;      # extraFlags = ["--dbformat=slocate"];
      prunePaths = lib.mkOptionDefault [
        "/ancilla/media/other"
      ];
    };

    openssh = {
      enable = true;
      forwardX11 = true;
      allowSFTP = true;
      kexAlgorithms = lib.mkOptionDefault [
        "diffie-hellman-group14-sha1"
      ];
      macs = lib.mkOptionDefault [
        "hmac-sha1"
      ];
      # Scanner only uses legacy key types, so we need to enable them here.
      extraConfig = ''
        PubkeyAcceptedKeyTypes +ssh-dss,ssh-rsa
        HostKeyAlgorithms +ssh-dss,ssh-rsa
        Match user scanner
          ForceCommand ${pkgs.openssh}/libexec/sftp-server
          X11Forwarding no
          AllowTcpForwarding no
      '';
    };
  };

  programs.msmtp = {
    enable = true;
    accounts.default = {
      host = "smtp.thinktel.ca";
      domain = "ancilla.ancilla.ca";
      tls = "on";
      tls_starttls = "off";
      #tls_trust_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      from = "%U@ancilla.ca";
      user = secrets.msmtp-user;
      password = secrets.msmtp-password;
    };
  };

  users.users.scanner = {
    isSystemUser = true;
    description = "ADS-1700W scanner receptron";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDujmZgyB8AO4rpcDokqM74EbD3Vm7gDvMHIliLzlWfqFEU3ItwkFQelHzYGDrZ/M9IE1jAvYjyZ7ylhyq/tYLmPkZMa42rzAO1yDRMy8dPC5g9kFFcswbFrqt4ExOlRgzdX/Dhz/zS6Fj46DpSBzfU7UWbBAR+gu5MVqUBo4ZY3QBmgj7Uhb1rTgPTIVSIlPUU/pPyXgA1FYgekcXP5Kl9Vpz6rNlDcnHBJNLr+X+fxKeidUSZRl+1rLwnlQTeWwscnCZpzPwfzLFc6bt6Tjtke0WxVKQI+q2D9jHxeF3Msw3iTioI05bDnkeYezd8azTcEGfqbt5IF79iUpJnRBF1 root@BR5CF3704E4CEA"
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1vSpVbx5fVJIK502nZl2ddk9VIbo7H06Up6eqk5brnFJG06gn9RtztFpIZaSUmDtdIlb9X0wSGGoiWGkwithc/79SvulOZD1X1DgNjjxIgXnNR1qlXm5ZjqjbWvL2NPKmyO7BP7IA1B0YkEj6sIQL7FWi7uIV/04qI/xSKPtGbhFtS+qoskv5p1GwhlJOuk3zKHJ7tue/CIiT8HEBl3OSGlQazItPOjLf4jkw7aE6Bl5pU8vbruUVry/SrXBo4AQw80H5Np6GCPrGj5eCDmsT4E+e5SZmaF414ih9YL6dtGXWWI2k13su9A3/OZ+UNx6Oz3iEoarkBPpap9VnhrbRQ== rebecca@thoth.ancilla.ca"
    ];
    home = "/ancilla/scans";
    createHome = false;
    useDefaultShell = true;
    group = "scanner";
  };
  users.groups.scanner = {};

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
