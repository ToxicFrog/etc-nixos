# Ancilla backup services using Borg.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
  borg = { name, ... } @ opts: ({
    archiveBaseName = name;
    extraCreateArgs = "--stats --progress --exclude-caches --files-cache=mtime,size --patterns-from=${../borg/. + "/${name}.borg"}";
    repo = "/mnt/external/borg-dir";
    paths = ["/dev/null"];
    startAt = [];
    encryption.mode = "none";
  } // removeAttrs opts ["name"]);
  borg-sshfs = { name, host ? opts.name, path ? ".", ... } @ opts: borg ({
    preHook = ''
      sshfs ${host}:${path} /mnt/backup -oro,reconnect
      cd /mnt/backup
    '';
    postHook = ''
      cd
      fusermount -u -z /mnt/backup
    '';
  } // removeAttrs opts ["host" "path"]);
in {
  services.borgbackup.jobs = {
    "funkyhorror" = borg-sshfs {
      name = "funkyhorror";
    };
    "godbehere.ca" = borg-sshfs {
      name = "godbehere.ca";
    };
    "grandriverallbreedrescue.ca" = borg-sshfs {
      name = "grandriverallbreedrescue.ca";
      host = "${secrets.grabr-user}@grandriverallbreedrescue.ca";
    };
    durandal = borg-sshfs {
      name = "durandal";
      path = "/";
    };
  };
}
