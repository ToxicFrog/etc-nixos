# Configuration for running multiple syncthing daemons.
# To enable syncthing for additional users, you must:
# - add that user to the 'linger' group
# - as that user, run:
#   mkdir -p ~/.config/systemd/user/default.target.wants
#   ln -s /etc/systemd/user/syncthing.service ~/.config/systemd/user/default.target.wants
#   systemctl --user daemon-reload
#   systemctl --user start syncthing
#   journalctl --user -u syncthing | grep announce=
# - add the announce= and listen= ports listed to the firewall rules below
{ config, pkgs, lib, ... }:

let prestart = ''
  BCASTPORT=$((21001 + UID%97))
  GUIPORT=$((BCASTPORT+100))
  LISTENPORT=$((BCASTPORT + 1000))

  echo "Applying per-user syncthing config: announce=$BCASTPORT listen=$LISTENPORT gui=$GUIPORT"

  ${pkgs.syncthing}/bin/syncthing generate
  sed -Ei "
    s,<localAnnouncePort>.*</localAnnouncePort>,<localAnnouncePort>$BCASTPORT</localAnnouncePort>,
    s,:[0-9]+</localAnnounceMCAddr>,:$BCASTPORT</localAnnounceMCAddr>,
    s,:[0-9]+</listenAddress>,:$LISTENPORT</listenAddress>,
    /<gui/,/gui>/ {
      s,:[0-9]+</address>,:$GUIPORT</address>,
    }
  " ~/.config/syncthing/config.xml
''; in
{
  networking.firewall = {
    allowedTCPPorts = [ 22071 22048 ];
    allowedUDPPorts = [ 22071 22048 21071 21048 ];
  };

  systemd.user.services.syncthing = {
    description = "Syncthing service";
    after = [ "network.target" ];
    environment = {
      STNORESTART = "yes";
      STNOUPGRADE = "yes";
    };
    wantedBy = [ "multi-user.target" ];
    preStart = prestart;
    serviceConfig = {
      Restart = "on-failure";
      SuccessExitStatus = "3 4";
      RestartForceExitStatus = "3 4";
      ExecStart = ''
        ${pkgs.syncthing}/bin/syncthing -no-browser
      '';
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = [
        "~CAP_SYS_PTRACE" "~CAP_SYS_ADMIN"
        "~CAP_SETGID" "~CAP_SETUID" "~CAP_SETPCAP"
        "~CAP_SYS_TIME" "~CAP_KILL"
      ];
    };
  };
}
