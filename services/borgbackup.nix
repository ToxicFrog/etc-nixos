# Ancilla backup services using Borg.

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
  hour = 60*60;
  day = hour*24;
  daily = day - hour;
  weekly = day * 7 - hour;
  preamble = ''
    # Append an "+n" to duplicate archive names.
    # So durandal-2018d123 becomes durandal-2018d123+1 the second time.
    archiveCount="$(${pkgs.borgbackup}/bin/borg list -P "$archiveName" | ${pkgs.coreutils}/bin/wc -l)"
    if (( archiveCount > 0 )); then
      archiveName="$archiveName+$archiveCount"
    fi
  '';
  borgcfg = pkgs.copyPathToStore ../borg;
  borg = { name, ... } @ opts: ({
    archiveBaseName = name;
    extraArgs = "--lock-wait=60";
    extraCreateArgs = builtins.concatStringsSep " " [
      "--stats"
      "--progress"
      "--exclude-caches"
      "--files-cache=mtime,size"
      "--exclude-if-present=.NOBACKUP"
      "--patterns-from=${borgcfg}/${name}.borg"
    ];
    repo = "/backup/borg-repo";
    paths = [];  # Paths are read from the --patterns-from file
    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat /backup/borg/passphrase";
    appendFailedSuffix = false;
    environment = {
      BORG_CONFIG_DIR = "/backup/borg/config";
      BORG_CACHE_DIR = "/backup/borg/cache";
      BORG_SECURITY_DIR = "/backup/borg/security";
      BORG_KEYS_DIR = "/backup/borg/keys";
    };
    readWritePaths = [
      "/backup/borg"
    ];
    startAt = ["*-*-* 02,08,10,12,14:01:00"];
    dateFormat = "+%Y%m%d";
  } // removeAttrs opts ["name"]);
  borg-sshfs = {
      name, touch,
      host ? opts.name,
      path ? ".",
      ...} @ opts: borg ({
    preHook = ''
      ${preamble}

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
    "borgbackup-job-${name}" = {
      serviceConfig = {
        Type = "oneshot";
        # borg uses exit(1) for warnings like "file deleted during backup".
        SuccessExitStatus = "1";
      };
      after = [];
    };
  };
  merge-and-order-services = first: second:
    if first.name == "" then
      second
    else
      let afters = first."borgbackup-job-${first.name}".after ++ ["borgbackup-job-${first.name}.service"];
      in lib.attrsets.recursiveUpdate
        (first // second)
        {
          "borgbackup-job-${second.name}".after = afters;
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
    ancilla = borg {
      name = "ancilla";
      minAge = daily;
      preHook = ''
        ${preamble}

        ssh localhost touch /root/.borgbackup
        cd /
      '';
    };
    durandal = borg-sshfs {
      name = "durandal";
      path = "/.";
      touch = "home/.borgbackup";
      minAge = weekly;
    };
    "funkyhorror" = borg-sshfs {
      name = "funkyhorror";
      touch = ".borgbackup";
      minAge = weekly;
    };
    "godbehere.ca" = borg-sshfs {
      name = "godbehere.ca";
      touch = ".borgbackup";
      minAge = weekly;
    };
    "grandriverallbreedrescue.ca" = borg-sshfs {
      name = "GRABR.ca";
      host = "${secrets.grabr-user}@grandriverallbreedrescue.ca";
      touch = ".borgbackup";
      minAge = weekly;
    };
    thoth = borg-sshfs {
      name = "thoth";
      path = "/.";
      touch = "root/.borgbackup";
      minAge = daily;
    };
  };
  systemd.services = borg-ordering [
    "ancilla"
    "thoth"
    "durandal"
    "godbehere.ca"
    "grandriverallbreedrescue.ca"
    "funkyhorror"
  ];
}
