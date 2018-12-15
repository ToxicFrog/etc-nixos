# Ancilla services not large enough to need their own file.

{ config, pkgs, lib, ... }:

let
  secrets = (import ./secrets/default.nix {});
in {
  imports = [
    ./munin/munin.nix
    ./services/bittorrent.nix
    ./services/borgbackup.nix
    ./services/bup.nix
    ./services/ipfs.nix
    ./services/media.nix
    ./services/minecraft.nix
    ./services/nginx.nix
    ./services/smb.nix
  ];

  users.users.git.createHome = lib.mkForce false;
  systemd.services.gitolite-init.after = ["local-fs.target"];

  services = {
    fail2ban.enable = true;  # temporarily disabled due to doing lots and lots of disk
    apcupsd.enable = true;
    bitlbee = {
      enable = true;
      plugins = with pkgs; [ bitlbee-facebook bitlbee-discord bitlbee-steam ];
      libpurple_plugins = with pkgs; [ purple-hangouts ];
    };

    monit = {
      enable = true;
      config = lib.readFile ./services/monit.conf;
    };

    smartd = {
      enable = true;
      # TODO: fix this so mail actually goes somewhere useful
      notifications.mail.mailer = "/run/current-system/sw/bin/sendmail";
      notifications.mail.enable = true;
      notifications.mail.recipient = "root@ancilla.ca";
    };

    # Gitolite git repo hosting (mostly used by Nightstar)
    gitolite = {
      enable = true;
      dataDir = "/srv/git";
      user = "git";
      adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8yJCgbZVMxI5mfzhRqPl5aP3yEksIrzCAf8IdoM38mxJRyu8fFxOu2iRiNHSUAWvFMvsslhs59DKMMoAdNy2qTIglpt4HAKM5TahYt88UmewbdEniLF3MhUlNwa0rAzFwB4V/X++0kBb5AmAYpESibGqPnpHqPMeMZeJHCP21GjhSduhS/rtdVv9wgm7Ng6Ezsh4Bxo/hPO9T4RmhMGV0V6JyFePBzQpvfWXlgiAWVpkRntFY3Io6+m3l0PBafqe+a2du6C+CgFgBUqBoOwM4kDBON2t6dpyQ+DxnLYLfMMv+sAer+Ko+mrZG6NyzoyZH6kPLwP5Jt68KtBpsHBfKw== bk@ancilla";
    };
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

    syncthing = {
      enable = true;
      systemService = false;
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
    path = with pkgs; [ curl ];
    serviceConfig.ExecStart = "${pkgs.curl}/bin/curl ${secrets.dyndns-url}";
    serviceConfig.Type = "oneshot";
  };
}
