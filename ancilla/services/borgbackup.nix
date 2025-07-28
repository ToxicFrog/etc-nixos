# Ancilla backup services using Borg.

{ config, pkgs, lib, secrets, ... }:

let
  patterns = import ../../shared/borg-patterns.nix;
  borg-rsync = name: host: path: {
    systemd.services."borgbackup-job-${name}".serviceConfig = {
      RandomizedDelaySec = toString (60*60*2);
      Restart = "on-failure";
      RestartSec = "600";
      SuccessExitStatus = "1";
      Type = "oneshot";
    };
    services.borgbackup.jobs."${name}" = {
      appendFailedSuffix = false;
      archiveBaseName = "${name}";
      compression = "auto,zstd";
      dateFormat = "+%Y%m%d.%H%M";
      doInit = false;
      encryption.mode = "repokey-blake2";
      encryption.passCommand = "cat /root/borg-passphrase";
      environment.BORG_USE_CHUNKS_ARCHIVE = "no";
      extraCreateArgs = [
        "--stats"
        "--progress"
        "--exclude-caches"
        "--exclude-if-present=.NOBACKUP"
      ];
      paths = [];  # All paths are specified in the patterns
      patterns = patterns."${name}";
      persistentTimer = true;
      preHook = ''
        mkdir -p /backup/cache/${name}
        cd /backup/cache/${name}
        ${pkgs.rsync}/bin/rsync -aSHAX --delete-before ${host}:${path}/ ./ || err=$?
        if ! (( err == 0 || err == 23 || err == 24 )); then
          # 23/24 are "some files not transferred" errors; on all other errors we should abort
          exit $err
        fi
        touch .borgbackup
      '';
      repo = "borg@ancilla.ancilla.ca:.";
      startAt = "weekly";
    };
  };
in lib.lists.fold lib.attrsets.recursiveUpdate {
  services.borgbackup.repos.ancilla-external = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0mn+eABoE9/DXQcJ3ysFz+S1enOeNuVHRe16cHIVGy root@ancilla"
    ];
    authorizedKeysAppendOnly = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQghF2NeCZRtvfguD0ZPbCBEy4AmXzmZVTwQGAvlZM8 root@thoth"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMTvcdoA9ZGGrUI3DY3v7ZsZ7Nbmd0Uk+fAgCg9AYvk root@durandal"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIF8epayZlkhHtnKTYPBJN8scn3I6LL/qWxSer5bC9H root@pladix"
    ];
    path = "/backup/borg-repo";
  };
} [
  (borg-rsync "funkyhorror" "funkyhorror" ".")
  (borg-rsync "godbehere.ca" "godbehere.ca" ".")
  (borg-rsync "GRABR.ca" "${secrets.auth.grabr.user}@grandriverallbreedrescue.ca" ".")
]
