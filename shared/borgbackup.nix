{ config, pkgs, lib, secrets, ... }:

let
  host = config.networking.hostName;
  patterns = import ./borg-patterns.nix;
in {
  systemd.services."borgbackup-job-${host}".serviceConfig = {
    RandomizedDelaySec = toString (60*60*2);
    Restart = "on-failure";
    RestartSec = "600";
    SuccessExitStatus = "1";
    Type = "oneshot";
  };
  services.borgbackup.jobs."${host}" = {
    appendFailedSuffix = false;
    archiveBaseName = "${host}";
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
    patterns = patterns."${host}";
    persistentTimer = true;
    repo = "borg@ancilla.ancilla.ca:.";
    startAt = "daily";
  };
}
