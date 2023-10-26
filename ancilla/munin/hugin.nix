# Hugin IRC message relay for Munin.
# Used for alert delivery by Munin and other alerting things like smartd.
# You can use it like sendmail, although it ignores all command line flags.

{ config, pkgs, lib, ... }:

let
  server = "nsvm.ancilla.ca";
  nick = "hugin";
  name = "ancilla notification daemon";
  channel = "#ancilla";
  user = "munin";
  group = "munin";
  serviceConfig = {
    User = "${user}";
    Group = "${group}";
    WorkingDirectory = "~";
    Restart = "always";
    RestartSec = 5;
  };
  hugin = pkgs.writeScriptBin "hugin" (builtins.readFile ./hugin.sh);
in {
  systemd.services.hugin-ii = {
    description = "IRC backend for Munin notifications";
    inherit serviceConfig;
    startLimitBurst = 3;
    startLimitIntervalSec = 10;
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    script = ''
      echo "Connecting..."
      ${pkgs.ii}/bin/ii \
        -i hugin \
        -s ${server} \
        -n ${nick} \
        -f "${name}" &
      while [[ ! -e "hugin/${server}/in" ]]; do
        sleep 1
      done
      echo "Joining..."
      while [[ ! -e "hugin/${server}/${channel}/in" ]]; do
        echo "/JOIN ${channel}" > ~${user}/hugin/${server}/in
        sleep 5
      done
      wait
    '';
    postStart = ''
      while [[ ! -e "hugin/${server}/${channel}/in" ]]; do
        sleep 1
      done
      echo "Ready!"
    '';
    postStop = ''
      ${pkgs.coreutils}/bin/rm -rf hugin
    '';
  };

  systemd.services.hugin-mqtt = {
    description = "MQTT listener for Munin notifications";
    inherit serviceConfig;
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "hugin-ii.service" "mosquitto.service"];
    partOf = ["hugin-ii.service"];
    requires = ["hugin-ii.service"];
    path = with pkgs; [ zsh jq mosquitto ];
    environment = { HUGIN_COLOUR = "irc"; };
    script = ''
      export PATH
      export HUGIN_COLOUR
      # hack hack hack -- prevent /etc/zshenv from overwriting PATH
      export __NIXOS_SET_ENVIRONMENT_DONE=1
      ${hugin}/bin/hugin 'hugin/#' > 'hugin/${server}/${channel}/in'
    '';
  };
}
