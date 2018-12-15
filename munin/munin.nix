# Configuration for the Munin monitoring system.

{ config, pkgs, lib, ... }:

{
  # Munin master to collect and graph metrics.
  services.munin-cron = {
    enable = true;
    extraGlobalConfig = ''
      htmldir /srv/www/munin
    '';
    # Monitor ancilla using a local node, and the rest of the network via proxy
    # plugins.
    hosts = ''
      [ancilla.ca;ancilla]
      use_node_name yes
      address localhost

      [ancilla.ca;helix]
      use_node_name no
      address localhost

      [ancilla.ca;traxus]
      use_node_name no
      address localhost
    '';
    # Light on dark theme.
    extraCSS = ''
      html, body {
        background: #222222;
      }
      #header, #footer {
        background: #333333;
      }
      img.i, img.iwarn, img.icrit, img.iunkn {
        filter: invert(100%) hue-rotate(-30deg);
      }
    '';
  };

  # Local node. This monitors ancilla directly and fetches data from other systems
  # on the network.
  services.munin-node = {
    enable = true;
    extraPlugins = {
      # TODO: replace with general purpose CPU/memory/sensors plugin.
      ssh_helix_uptime = ./ssh__uptime;
      http_traxus_onhub = ./http__onhub;
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

      [ssh_helix_*]
        env.ssh_target root@helix
    '';
    extraAutoPlugins = [
      /usr/src/munin-contrib/plugins/zfs
    ];
    disabledPlugins = [
      "buddyinfo"     # I don't care about memory fragmentation
      "diskstat_*"    # conflicts with diskstat
      "munin_stats"   # broken on NixOS
      "port_*"        # don't care about this either
      "zfs_arcstats"  # doesn't support ZoL
      "zpool_iostat"  # TODO: replace with per-pool rather than per-disk iostat
    ];
  };
}
