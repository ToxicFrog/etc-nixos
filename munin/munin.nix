# Configuration for the Munin monitoring system.
# To deploy the micronode on a raspi, use:
# env MUNIN_LIBDIR=$(systemctl cat munin-node | grep MUNIN_LIBDIR | cut -d\" -f2) \
#     ./micronode install root@raspi cpu load uptime acpi if_eth0=if_ if_wlan0=if_ cpuspeed
# after making sure that passwordless login works
# then edit the authorized_keys on the rpi and add: command="munin/micronode"
# in front of the key munin will be using.

{ config, pkgs, lib, ... }:

{
  # Munin master to collect and graph metrics.
  services.munin-cron = {
    enable = true;
    extraGlobalConfig = ''
      htmldir /srv/www/munin
      ssh_command /run/current-system/sw/bin/ssh

      contact.irc.command /run/current-system/sw/bin/hugin "\#ancilla"
      contact.irc.text === ''${var:host} :: ''${var:graph_title} ===\n\
        ''${if:cfields === ToxicFrog: ''${var:host} :: ''${var:graph_title} CRITICAL ===\n}\
        ''${loop:fofields \
        3  ''${var:label}: ''${var:value}\
        ''${if:extinfo : \n    ''${var:extinfo}}\n}\
        ''${loop:wfields \
        7  ''${var:label}: ''${var:value}\
        1[''${var:wrange}]\
        ''${if:extinfo : \n    ''${var:extinfo}}\n}\
        ''${loop:cfields \
        4  ''${var:label}: ''${var:value}\
        1[''${var:crange}]\
        ''${if:extinfo : \n    ''${var:extinfo}}\n}\
        === END ===\n\
        
    '';
    # Monitor ancilla using a local node, and the rest of the network via proxy
    # plugins.
    hosts = ''
      [ancilla.ca;ancilla]
      use_node_name yes
      address localhost

      [ancilla.ca;helix]
      use_node_name no
      address ssh://root@helix/

      [ancilla.ca;oculus]
      use_node_name no
      address ssh://root@oculus/

      [ancilla.ca;traxus]
      use_node_name no
      address localhost
    '';
    # Light on dark theme.
    extraCSS = ''
      html, body { background: #222222; }
      #header, #footer { background: #333333; }
      body, h1, h2, h3, p, span, div { color: #888888; }
      img.i, img.iwarn, img.icrit, img.iunkn {
        filter: invert(100%) hue-rotate(-30deg);
      }
      #legend th { border-bottom: 1px solid #bbbbbb; }
      #legend .oddrow { background-color: #222222; }
      #legend .oddrow td { border-bottom: 1px solid #666666; }
      #legend .evenrow { background-color: #282828; }
      #legend .evenrow td { border-bottom: 1px solid #666666; }
    '';
  };

  # Local node. This monitors ancilla directly and fetches data from other systems
  # on the network.
  services.munin-node = {
    enable = true;
    extraPlugins = {
      http_traxus_onhub = ./http__onhub;
      borgbackup = ./borgbackup;
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

      [http_traxus_onhub]
        env.name_64bc0cf4a1d3 symbol-phone
        env.name_e442a6ab3cb6 isis
        env.name_404e36863091 auxilior
        env.name_54ab3aba8d0c lilypad
        env.name_58b0d4862ab5 kobo
        env.name_f4f1e1dfab8f squeezebox

      [borgbackup]
        user root
        env.backup_prefixes ancilla::24 thoth::24 durandal::168 godbehere.ca::168 funkyhorror::168 GRABR.ca::168
        env.BORG_REPO /backup/borg-repo
        env.BORG_PASSCOMMAND cat /backup/borg/passphrase
        env.BORG_CONFIG_DIR /backup/borg/config
        env.BORG_CACHE_DIR /backup/borg/cache
        env.BORG_SECURITY_DIR /backup/borg/security
        env.BORG_KEYS_DIR /backup/borg/keys

      [sensors_*]
        env.sensors sensors -c /etc/sensors3.conf
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
      "zfs_arcstats"  # doesn't support ZoL
      "zpool_iostat"  # TODO: replace with per-pool rather than per-disk iostat
    ];
  };
  # concat with ${pkgs.lm-sensors}/etc/sensors3.conf
  environment.etc."sensors3.conf".text = builtins.concatStringsSep "\n" [
    (builtins.readFile "${pkgs.lm_sensors}/etc/sensors3.conf")
    ''
      chip "iwlwifi-*"
      label temp1 "WiFi temperature"

      chip "amdgpu-pci-3800"
      set temp1_max 80
      set temp1_max_hyst 70

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
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.lm_sensors}/bin/sensors -c /etc/sensors3.conf -s";
    };
  };
}
