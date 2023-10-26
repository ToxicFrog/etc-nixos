{ pkgs, ... }:

{
  # Allow TCP pulse access for use by snapclient etc
  environment.etc."pipewire/pipewire-pulse.conf.d/99-pulse-tcp.conf".text = ''
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
  environment.etc."wireplumber/main.lua.d/99-disable-suspend.lua".text = ''
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
    };
  };
}
