# Ancilla services not large enough to need their own file.

{ config, pkgs, lib, secrets, unstable, ... }:

let
  localpkgs = (import /home/bex/devel/nixpkgs {});
in {
  imports = [
    ../../secrets/scanner.nix
    ../munin/munin.nix
    ../munin/hugin.nix
    ./bittorrent.nix
    ./borgbackup.nix
    ./crossfire.nix
    ./doomrl-server.nix
    ./headscale.nix
    ./library.nix
    ./mastodon.nix
    ./matrix.nix
    ./minecraft.nix
    ./music.nix
    ./nfs.nix
    ./nginx.nix
    # ./photos.nix  # pgvecto-rs is broken in 24.05
    ./smarthome.nix
    ./smb.nix
    ./syncthing.nix
    ./taskd.nix
    ./timelapse.nix
    ./tv.nix
    # ./vncdesktop.nix
    # secrets.personal-services
  ];

  users.users.git.createHome = lib.mkForce false;
  systemd.services.gitolite-init.after = ["local-fs.target"];

  # ftpd & CUPS
  networking.firewall.allowedTCPPorts = [ 20 21 631 ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 21020; to = 21029; } # vsftpd PASV
  ];

  services = {
    # A'Tuin shell history synchronization
    atuin = {
      enable = true;
      openRegistration = false;
      port = 28034; # Unicode for TURTLE is 0x128034
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureUsers = [{
          name = "atuin";
          ensureDBOwnership = true;
          # ensurePermissions = {
          #   # "DATABASE atuin" = "ALL PRIVILEGES";
          #   "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
          # };
      }];
    };
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

    etcd.enable = true;
    etcd.dataDir = "/srv/etcd";

    fail2ban = {
      enable = true;
      ignoreIP = ["192.168.1.0/24"];
    };

    apcupsd = {
      enable = true;
      configText = ''
        UPSTYPE usb
        NISIP 127.0.0.1
        BATTERYLEVEL 10
        MINUTES 5
        KILLDELAY 0
        NOLOGON disable
      '';
    };
    bitlbee = {
      enable = true;
      plugins = with pkgs; [ bitlbee-mastodon bitlbee-facebook ];
      # plugins = with pkgs; [ unstable.bitlbee-facebook unstable.bitlbee-steam ];
      # libpurple_plugins = with pkgs; [ purple-hangouts ];
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

    # tlp.enable = true;
    locate.prunePaths = lib.mkOptionDefault [
      "/ancilla/media/other"
    ];

    openssh.ports = [ 22 2222 ];  # Workaround for Bell's busted-ass router firmware
    # openssh.extraConfig = ''
    #   PubkeyAcceptedKeyTypes +ssh-rsa
    #   HostKeyAlgorithms +ssh-rsa
    # '';
    zfs.autoSnapshot = {
      # default settings keep:
      # - 4 15-minute snapshots
      # - 24 hourly
      # - 7 daily
      # - 12 monthly
      enable = true;
      flags = "-p -u";
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
      user = secrets.auth.msmtp.user;
      password = secrets.auth.msmtp.pass;
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

  systemd.services.food-of-tyria = {
    description = "Food of Tyria tracker";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    requires = ["network-online.target" "local-fs.target"];
    environment.PORT = "8099";
    serviceConfig = {
      User = "bex"; Group = "users";
      ExecStart = "${pkgs.jre}/bin/java -jar /home/bex/devel/tyria/target/food-of-tyria-0.1.0-SNAPSHOT-standalone.jar";
      Restart = "always";
      RestartSec = 15;
      WorkingDirectory = "/home/bex/devel/tyria";
    };
  };
}
