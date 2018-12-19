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

      [borgbackup]
        user root
        env.backup_prefixes ancilla::24 thoth::24 durandal::168 godbehere.ca::168 funkyhorror::168 GRABR.ca::168
        env.BORG_REPO /backup/borg-repo
        env.BORG_PASSCOMMAND cat /backup/borg/passphrase
        env.BORG_CONFIG_DIR /backup/borg/config
        env.BORG_CACHE_DIR /backup/borg/cache
        env.BORG_SECURITY_DIR /backup/borg/security
        env.BORG_KEYS_DIR /backup/borg/keys
    '';
    extraAutoPlugins = [
      /usr/src/munin-contrib/plugins/zfs
    ];
    disabledPlugins = [
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
}
