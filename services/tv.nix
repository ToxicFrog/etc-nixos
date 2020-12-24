# Configuration for media servers -- plex (video) and airsonic (music).

{ config, pkgs, lib, ... }:

let
  secrets = (import ../secrets/default.nix {});
in {
  networking.firewall.allowedTCPPorts = [8096]; # DLNA media fetch
  networking.firewall.allowedUDPPorts = [1900 7359]; # DLNA discovery
  users.users.jellyfin.extraGroups = ["render"]; # HW video codecs
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = with pkgs; [libvdpau-va-gl vaapiVdpau];
  services = {
    jellyfin.enable = true;
    jellyfin.package = pkgs.jellyfin;
    nginx.virtualHosts."tv.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      # basicAuth = secrets.plex-auth;
      locations."/" = {
        proxyPass = "http://localhost:8096/";
        extraConfig = "proxy_buffering off;";
      };
      locations."/socket" = {
        proxyPass = "http://localhost:8096/socket";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
        '';
      };
    };
  };

  # Automatically turn off Oculus's USB ports, thus shutting off the Chromecast,
  # every night, so that it doesn't wake the screen back up and blast the entire
  # room with light when it reboots for updates at 2am every morning.
  # Seriously, why can't you turn that off?
  # systemd.services.oculus-chromecast-off = {
  #   startAt = ["*-*-* 01:00:00"];
  #   script = ''echo 1-1 | ${pkgs.openssh}/bin/ssh root@oculus tee /sys/bus/usb/drivers/usb/unbind'';
  # };
  # systemd.services.oculus-chromecast-on = {
  #   startAt = ["*-*-* 09:00:00"];
  #   script = ''echo 1-1 | ${pkgs.openssh}/bin/ssh root@oculus tee /sys/bus/usb/drivers/usb/bind'';
  # };
}
