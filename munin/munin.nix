# Configuration for the Munin monitoring system.
# To deploy the micronode on a raspi, use:
# env MUNIN_LIBDIR=$(systemctl cat munin-node | grep MUNIN_LIBDIR | cut -d\" -f2) \
#     ./micronode install root@raspi cpu load uptime acpi if_eth0=if_ if_wlan0=if_ cpuspeed
# after making sure that passwordless login works
# then edit the authorized_keys on the rpi and add: command="munin/micronode"
# in front of the key munin will be using.

{ config, pkgs, lib, ... }:

let
  muninConf =
    (builtins.head (builtins.match ".*--config (/nix/store/[^ ]+munin.conf).*"
                config.systemd.services.munin-cron.serviceConfig.ExecStart));

in {
  services.fcgiwrap.enable = true;
  services.fcgiwrap.user = "munin";
  services.fcgiwrap.group = "nogroup";
  services.nginx.virtualHosts."ancilla.ancilla.ca".locations."/munin-cgi/" = {
    alias = "${pkgs.munin}/www/cgi/";
    extraConfig = ''
      fastcgi_split_path_info /munin-cgi/([^/]+)([^?]*);
      fastcgi_param REQUEST_METHOD $request_method;
      fastcgi_param CONTENT_TYPE $content_type;
      fastcgi_param CONTENT_LENGTH $content_length;
      fastcgi_param QUERY_STRING $query_string;
      fastcgi_param SCRIPT_FILENAME ${pkgs.munin}/www/cgi/$fastcgi_script_name;
      fastcgi_param CGI_DEBUG true;
      fastcgi_param MUNIN_CONFIG ${muninConf};
      fastcgi_param PATH_INFO $fastcgi_path_info;
      fastcgi_pass unix:${config.services.fcgiwrap.socketAddress};
    '';
  };
  # Munin master to collect and graph metrics.
  services.munin-cron = {
    enable = true;
    extraGlobalConfig = ''
      htmldir /srv/www/munin
      ssh_command /run/current-system/sw/bin/ssh
      cgitmpdir /var/lib/munin/cgi-tmp

      # TODO
      # migrate to larger RRDs
      # this probably means:
      # - shut off munin
      # - rrdtool dump on all RRDs
      # - delete all RRDs (snapshot first!)
      # - run munin once to generate new RRDs
      # - rrdtool import to populate new RRDs
      # question: will rrdtool import be able to do the thing given that the new
      # RRDs will have a different step size (5m/1h/1d rather than 5m/30m/2h/1d)
      # and RRA count?
      #graph_data_size custom 2d, 30m for 9d, 2h for 45d, 1d for 450d
      graph_data_size custom 1t, 1h for 1y, 1d for 10y

      contact.irc.command /run/current-system/sw/bin/hugin "\#ancilla"
      contact.irc.max_messages 1
      contact.irc.text ''${var:host}\t''${var:graph_title}\n\
        ''${loop:cfields CRIT\t''${var:label}\t''${var:value}\t''${var:crange}\t''${var:extinfo}\n}\
        ''${loop:wfields WARN\t''${var:label}\t''${var:value}\t''${var:wrange}\t''${var:extinfo}\n}\
        ''${loop:fofields FOK\t''${var:label}\t''${var:value}\t-\t''${var:extinfo}\n}'';

    # Monitor ancilla using a local node, and the rest of the network via proxy
    # plugins.
    hosts = ''
      [ancilla.ca;ancilla]
      use_node_name yes
      address localhost

      [ancilla.ca;nanolathe]
      use_node_name no
      address localhost

      [ancilla.ca;octopi]
      use_node_name yes
      address octopi

      [ancilla.ca;openwrt]
      use_node_name no
      address openwrt

      [ancilla.ca;traxus]
      use_node_name no
      address localhost

      [ancilla.ca;pladix]
      use_node_name yes
      address pladix

      [ancilla.ca;isis]
      use_node_name yes
      address isis

      [ancilla.ca;ancilla.ca]
      use_node_name no
      address localhost

      [ancilla.ca;thoth]
      use_node_name yes
      address thoth.ancilla.ca

      [ancilla.ca;meatspace]
      use_node_name no
      address localhost
    '';
    # Light on dark theme.
    extraCSS = ''
      html, body { background: #222222; }
      #header, #footer { background: #333333; }
      body, h1, h2, h3, p, span, div { color: #888888; }
      /*
      img.i, img.iwarn, img.icrit, img.iunkn {
        filter: invert(1) hue-rotate(180deg) saturate(2);
      }
      */
      #legend th { border-bottom: 1px solid #bbbbbb; }
      #legend .oddrow { background-color: #222222; }
      #legend .oddrow td { border-bottom: 1px solid #666666; }
      #legend .evenrow { background-color: #282828; }
      #legend .evenrow td { border-bottom: 1px solid #666666; }
    '';
  };

  # Hack to invert luminance of graphs after munin-cron generates them.
  systemd.services.munin-cron.postStart = ''
    cd /srv/www/munin
    ${pkgs.findutils}/bin/find ancilla.ca -name '*.png' -newer .inverted -exec \
      ${pkgs.imagemagick}/bin/mogrify -colorspace HSL -channel B -negate +channel -colorspace sRGB '{}' ';'
    touch .inverted
  '';

  # Local node. This monitors ancilla directly and fetches data from other systems
  # on the network.
  services.munin-node = {
    enable = true;
    extraPlugins = {
      http_traxus_onhub = ./http__onhub;
      http_nanolathe_prusaconnect = ./http__prusaconnect;
      borgbackup = ./borgbackup;
      certificates = ./certificates;
      whois = ./whois;
      zpool_health = ./zpool_health;
      biometrics = ./biometrics;
      house_sensors = ./house_sensors;
    };
    extraPluginConfig = ''
      [df]
        env.exclude none unknown rootfs iso9660 squashfs udf romfs ramfs debugfs cgroup_root devtmpfs tmpfs
        env.warning 90
        env.critical 95

      [df_abs]
        env.exclude none unknown rootfs iso9660 squashfs udf romfs ramfs debugfs cgroup_root devtmpfs tmpfs

      [df_inode]
        env.exclude none unknown rootfs iso9660 squashfs udf romfs ramfs debugfs cgroup_root devtmpfs tmpfs nilfs2 vfat

      [certificates]
        env.domains ancilla.ancilla.ca music.ancilla.ca library.ancilla.ca phobos.ancilla.ca tv.ancilla.ca
        env.host_name ancilla.ca

      [whois]
        env.domains ancilla.ca godbehere.ca
        env.host_name ancilla.ca
        env.whois ${pkgs.whois}/bin/whois

      [http_traxus_onhub]
        env.name_64bc0cf4a1d3 symbol-phone
        env.name_58b0d4862ab5 kobo
        timeout 60

      [borgbackup]
        user root
        env.backup_prefixes ancilla::24 thoth::24 pladix::168 isis::168 durandal::168 godbehere.ca::168 funkyhorror::168 GRABR.ca::168
        env.info_cache_dir /backup/borg/info-cache
        env.BORG_REPO /backup/borg-repo
        env.BORG_PASSCOMMAND cat /backup/borg/passphrase
        env.BORG_CONFIG_DIR /backup/borg/config
        env.BORG_CACHE_DIR /backup/borg/cache
        env.BORG_SECURITY_DIR /backup/borg/security
        env.BORG_KEYS_DIR /backup/borg/keys

      [sensors_*]
        env.sensors sensors -c /etc/sensors3.conf
        env.ignore_temp4 true
        env.volt_warn_percent 20

      [zfs_*]
        user root

      [zpool_*]
        user root

      [zpool_health]
        env.zpool ${pkgs.zfs}/bin/zpool
    '';
    extraAutoPlugins = [
      /usr/src/munin-contrib/plugins/zfs
    ];
    disabledPlugins = [
      "acpi"          # sensors_ works better
      "cpuspeed"      # so noisy it's useless
      "buddyinfo"     # don't care about memory fragmentation
      "meminfo"       # duplicate of above
      "diskstat_*"    # conflicts with diskstat
      "munin_stats"   # broken on NixOS
      "port_*"        # don't care about this either
      "proc"          # doesn't work
      "zfs_arcstats"  # doesn't support ZoL
      "zpool_iostat"  # TODO: replace with per-pool rather than per-disk iostat
    ];
  };
  # concat with ${pkgs.lm-sensors}/etc/sensors3.conf
  environment.etc."sensors3.conf".text = builtins.concatStringsSep "\n" [
    (builtins.readFile "${pkgs.lm_sensors}/etc/sensors3.conf")
    ''
      chip "iwlwifi-*"
      label temp1 "WiFi"

      chip "amdgpu-pci-3800"
      label temp1 "GPU"
      # driver doesn't permit setting temperature limits
      # unfortunately driver also reports crit_hyst limit as 0C so the alarm will
      # be firing forever
      # set temp1_crit 80.0
      # set temp1_crit_hyst 80.0

      chip "nct6795-*"
      label fan2 "CPU Fan"
      label fan3 "Case Fans"
      # no corresponding headers on motherboard
      ignore fan1
      ignore fan4
      ignore fan5

      # no labels, not sure what any of these are or what their thresholds should
      # be; some of them are probably calced wrong too.
      ignore in1
      ignore in4
      ignore in5
      ignore in6
      ignore in9
      ignore in10
      ignore in11
      ignore in12
      ignore in13
      ignore in14

      # Reading 0 or fewer degrees
      ignore temp6
      ignore temp8
      ignore temp9
      ignore temp10

      # thresholds are wrong
      set temp1_max 115
      set temp1_max_hyst 90
      set in0_min 0.75
    ''
  ];
  systemd.services.lmsensors-load-thresholds = rec {
    description = "Load sensor configuration and thresholds";
    wantedBy = [ config.systemd.defaultUnit ];
    after = [ "systemd-udev-settle.service" "local-fs.target" ] ++ wantedBy;
    restartTriggers = ["/etc/sensors3.conf"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.lm_sensors}/bin/sensors -c /etc/sensors3.conf -s";
    };
  };
}
