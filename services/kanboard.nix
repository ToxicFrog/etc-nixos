{ config, pkgs, lib, ... }:

let
  # We can't use symlinkJoin here because Kanboard uses PHP's __DIR__ to find
  # config.php, and __DIR__ follows symlinks, which means it ends up looking
  # in ${pkgs.kanboard} rather than in ${kanboard-with-config}.
  rsyncJoin = name: paths:
    pkgs.runCommand name {
      paths = paths;
      preferLocalBuild = true;
      allowSubstitutes = false;
      passAsFile = "paths";
    } ''
      umask
      mkdir -p $out
      ls -lda $out
      for src in $(cat $pathsPath); do
        ${pkgs.rsync}/bin/rsync -r --chmod=Dug+w "$src/" "$out/"
      done
      rm -r $out/share/kanboard/data
    '';
  host = "ancilla.ancilla.ca";
  location = "/kanboard";
  dataDir = "/srv/kanboard";
  user = "kanboard";
  group = "nginx";
  settings = {
    DATA_DIR = "${dataDir}/data";
    PLUGINS_DIR = "${dataDir}/plugins";
    PLUGIN_INSTALLER = "true";
  };
  configFile = pkgs.writeTextDir "share/kanboard/config.php" ''
    <?php

    ${lib.concatStrings (lib.mapAttrsToList
        (k: v: "define('${k}', '${v}');\n") settings)}
  '';
  kanboard-with-config = rsyncJoin "kanboard-with-config" [
    "${pkgs.kanboard}"
    "${configFile}"
  ];
in {
  users.users."${user}" = {
    isSystemUser = true;
    description = "Kanboard user";
    home = dataDir;
    createHome = true;
    # on home creation, we also have to create ~/data ~/plugins ~/files and make them writeable
  };

  services.phpfpm.pools.kanboard = {
    user = user;
    group = group;
    phpPackage = pkgs.php;
    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 16;
      # "pm.start_servers" = 1;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 2;
      # "pm.max_requests" = 500;
      "listen.group" = config.services.nginx.group;
      "catch_workers_output" = "true";
      "chdir" = "${dataDir}";
      # "error_log" = "syslog";
      # "access.log" = "/tmp/fpmkanboard.log";
    };
  };

  services.nginx.virtualHosts."${host}".extraConfig = ''
    location = ${location} { return 307 ${location}/index.php?$args; }
    location = ${location}/ { return 307 ${location}/index.php?$args; }
    location ${location}/ {
      alias ${dataDir}/;
      index index.php;
      try_files $uri $uri/ ${location}/index.php?$args;

      location ~ \.php(?:$|/) {
        root ${kanboard-with-config}/share;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on; # Use only if HTTPS is configured
        include ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_pass unix:${config.services.phpfpm.pools.kanboard.socket};
      }

      location ${location}/assets/ {
        root ${kanboard-with-config}/share/;
      }

      location ${location}/data/files/ {
        alias ${dataDir}/data/files/;
      }

      location ${location}/data {
        deny all;
      }

      location ~ ${location}/\.ht {
        deny all;
      }
    }
  '';
}
