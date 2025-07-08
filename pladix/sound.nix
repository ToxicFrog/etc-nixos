{ pkgs, ... }:

{
  # Allow TCP pulse access for use by snapclient etc
  services.pipewire.pulse.enable = true;
  # services.pipewire.extraConfig.pipewire-pulse."99-pulse-tcp" = ''
  #   pulse.properties = {
  #     server.address = [
  #       "unix:native"
  #       {
  #         address = "tcp:127.0.0.1:4713"
  #         client.access = "allowed"
  #       }
  #     ]
  #   }
  # '';

  # Enable upmixing from 2.x and 3.x audio to 5.1 by linking the upstream upmix
  # configuration files into /etc/pipewire.
  # We need to do it this way instead of using environment.etc because the latter
  # is disabled by the pipewire config module. :<
  services.pipewire.configPackages = [
    (pkgs.runCommandLocal "pipewire-upmix" {} ''
      mkdir -p $out/share/pipewire/{pipewire,pipewire-pulse}.conf.d/
      cd $out/share/pipewire
      ln -s ${pkgs.pipewire}/share/pipewire/pipewire.conf.avail/20-upmix.conf pipewire.conf.d/
      ln -s ${pkgs.pipewire}/share/pipewire/pipewire-pulse.conf.avail/20-upmix.conf pipewire-pulse.conf.d/
    '')
  ];

  services.pipewire.wireplumber.extraConfig."99-disable-suspend" = {
    "monitor.alsa.rules" = [{
      matches = [{ "node.name" = "~alsa_output.*"; }];
      actions = {
        update-props = {
          "dither.noise" = 1;
          "node.pause-on-idle" = false;
          "session.suspend-timeout-seconds" = 0;
        };
      };
    }];
  };

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
