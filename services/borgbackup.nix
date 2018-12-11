# Ancilla backup services using Borg.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
  borgcfg = pkgs.copyPathToStore ../borg;
  borg = { name, ... } @ opts: ({
    archiveBaseName = name;
    extraCreateArgs = "--stats --progress --exclude-caches --files-cache=mtime,size --patterns-from=${borgcfg}/${name}.borg";
    repo = "/mnt/external/borg-dir";
    paths = [];
    encryption.mode = "none";
    appendFailedSuffix = false;
    dateFormat = "+%Yd%j";
  } // removeAttrs opts ["name"]);
  borg-sshfs = {
      name, touch,
      host ? opts.name,
      path ? ".",
      ...} @ opts: borg ({
    preHook = ''
      # Append an "+n" to duplicate archive names.
      # So durandal-2018d123 becomes durandal-2018d123+1 the second time.
      archiveCount="$(${pkgs.borgbackup}/bin/borg list -P "$archiveName" | ${pkgs.coreutils}/bin/wc -l)"
      if (( archiveCount > 0 )); then
        archiveName="$archiveName+$archiveCount"
      fi

      # Workaround for borgbackup dropping cache entries for the most recently
      # modified files in the backup dataset, c.f.
      # https://borgbackup.readthedocs.io/en/stable/faq.html#i-am-seeing-a-added-status-for-an-unchanged-file
      # This also means that if we can't ssh into the host we'll abort before
      # trying to mount it.
      ssh ${host} touch "${path}/${touch}"

      # mount the backup source
      ${pkgs.sshfs}/bin/sshfs ${host}:${path} /mnt/backup \
        -o ro,reconnect,workaround=rename
      cd /mnt/backup
    '';
    postHook = ''
      cd
      ${pkgs.fuse}/bin/fusermount -u -z /mnt/backup
    '';
  } // removeAttrs opts ["host" "path" "touch"]);
  name-to-service = name: {
    name = name;
    "borgbackup-job-${name}".serviceConfig = {
      Type = "oneshot";
      # borg uses exit(1) for warnings like "file deleted during backup".
      SuccessExitStatus = "1";
    };
  };
  merge-and-order-services = first: second:
    if first.name == "" then
      second
    else
      lib.attrsets.recursiveUpdate
        (first // second)
        {
          "borgbackup-job-${second.name}".after = ["borgbackup-job-${first.name}.service"];
        };
  borg-ordering = names:
    removeAttrs
      (builtins.foldl'
        merge-and-order-services
        { name = ""; }
        (map name-to-service names))
      ["name"];
in {
  services.borgbackup.jobs = {
    durandal = borg-sshfs {
      name = "durandal";
      path = "/.";
      touch = "home/.borgbackup";
      startAt = "Mon *-*-* 02:00:00";
    };
    "funkyhorror" = borg-sshfs {
      name = "funkyhorror";
      touch = ".borgbackup";
      startAt = "Mon *-*-* 02:00:00";
    };
    "godbehere.ca" = borg-sshfs {
      name = "godbehere.ca";
      touch = ".borgbackup";
      startAt = "Mon *-*-* 02:00:00";
    };
    "grandriverallbreedrescue.ca" = borg-sshfs {
      name = "GRABR.ca";
      host = "${secrets.grabr-user}@grandriverallbreedrescue.ca";
      touch = ".borgbackup";
      startAt = "Mon *-*-* 02:00:00";
    };
    thoth = borg-sshfs {
      name = "thoth";
      path = "/.";
      touch = "root/.borgbackup";
      startAt = "*-*-* 02:00:00";
    };
  };
  systemd.services = borg-ordering [
    "thoth"
    "durandal"
    "godbehere.ca"
    "grandriverallbreedrescue.ca"
    "funkyhorror"
  ];
}
