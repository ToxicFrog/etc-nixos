{ pkgs, ... }:

{
  # Allow TCP pulse access for use by snapclient etc
  services.pipewire.pulse.enable = true;
  services.pipewire.extraConfig.pipewire-pulse."99-pulse-tcp.conf" = ''
    pulse.properties = {
      server.address = [
        "unix:native"
        {
          address = "tcp:127.0.0.1:4713"
          client.access = "allowed"
        }
      ]
    }
  '';
  # Disable suspend and produce 1 bit of dither so that the amp doesn't go to
  # sleep.
  services.pipewire.wireplumber.extraScripts."99-disable-suspend.lua" = ''
    table.insert(alsa_monitor.rules,
      {
        matches = {{{ "node.name", "matches", "alsa_output.*" }}};
        apply_properties = {
          ["dither.noise"] = 1;
          ["node.pause-on-idle"] = false;
          ["session.suspend-timeout-seconds"] = 0;
        }
      }
    )
  '';

  # This is a user service!!
  # It needs to be enabled mutably using systemctl.
  systemd.user.services.snapclient = {
    wantedBy = [ "pipewire.service" ];
    after = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.snapcast}/bin/snapclient -h ancilla";
      Restart = "always";
      RestartSec = "60s";
    };
  };
}
