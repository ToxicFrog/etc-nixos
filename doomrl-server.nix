{ config, lib, pkgs, ... }:

with lib;
let
  server-path = "/srv/doomrl";
  config-file = ''
    doom_path ${pkgs.doomrl}/opt/doomrl
    data_path ${pkgs.doomrl-server}/share/doomrl-server
    user_path ${server-path}
  '';
in {
  security.acme.certs."phobos.ancilla.ca".email = "webmaster@ancilla.ca";

  # So that they appear in /run/current-system/sw.
  #environment.systemPackages = with pkgs; [doomrl doomrl-server];
  #environment.pathsToLink = [ "/share/doomrl-server" "/opt/doomrl" ];

  networking.firewall.allowedTCPPorts = [3666 3667];

  environment.etc."doomrl-server.conf" = {
    enable = true;
    uid = 666;
    gid = 0;
    text = config-file;
  };

  users.users.doomrl = {
    isSystemUser = true;
    description = "DoomRL-server user";
    home = "${server-path}";
    uid = 666;
  };

  services.xinetd = {
    enable = true;
    services = singleton {
      name = "doomrl-server";
      server = "${pkgs.inetutils}/libexec/telnetd";
      serverArgs = "-h -E ${pkgs.doomrl-server}/share/doomrl-server/doomrl-server";
      user = "doomrl";
      protocol = "tcp";
      port = 3666;
      unlisted = true;
      extraConfig = "env = PATH=${pkgs.less}/bin:${pkgs.nano}/bin:${pkgs.python3}/bin";
    };
  };

  # Websockify forwards requests from the web interface to the telnetd.
  services.networking.websockify = {
    enable = true;
    sslCert = "/var/lib/acme/phobos.ancilla.ca/fullchain.pem";
    sslKey = "/var/lib/acme/phobos.ancilla.ca/key.pem";
    portMap = {
      "3667" = 3666;
    };
  };

  # nginx serves the static doomRL website.
  services.nginx.virtualHosts."phobos.ancilla.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/".root = "${server-path}/www";
  };
}
