# General configuration shared between all of the systems that are primarily
# used by alex -- isis, pladix, and lots-of-cats.

{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./users.nix
  ];

  # Enable sound with pipewire.
  # TODO: systemwide?
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
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
}
