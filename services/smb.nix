# Samba file server configuration.

{ config, pkgs, ... }:

{
  # For SMB
  networking.firewall.allowedTCPPorts = [ 139 445 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];
  services.samba = {
    enable = true;
    syncPasswordsByPam = true;
    extraConfig = ''
    guest account = nobody
    map to guest = Bad User
    [homes]
      browsable = no
      writable = yes
    '';
    shares = {
      # Current mountpoints.
      ancilla = {
        browseable = "yes";
        comment = "/ancilla";
        path = "/ancilla";
        "read only" = false;
      };
      installs = {
        browseable = "yes";
        comment = "/ancilla/installs";
        path = "/ancilla/installs";
        "read only" = false;
      };
      media = {
        browseable = "yes";
        comment = "/ancilla/media";
        path = "/ancilla/media";
        "read only" = false;
      };
      # Legacy mountpoints.
      ancilla_installs = {
        browseable = "no";
        comment = "/ancilla/installs";
        path = "/ancilla/installs";
        "read only" = false;
      };
      ancilla_media = {
        browseable = "no";
        comment = "/ancilla/media";
        path = "/ancilla/media";
        "read only" = false;
      };
    };
  };
}
