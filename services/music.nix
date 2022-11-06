# Configuration for music streaming.
# At the moment this just means Airsonic, with streaming to the browser via the
# web client and to mobile devices via Ultrasonic.
# It may in the future include some sort of whole-home sound system using MPD
# and SnapCast, or something.

{ config, pkgs, lib, ... }:

let
  ffprobe-subsong-wrapper = pkgs.writeShellScriptBin "ffprobe" ''
    exec ${pkgs.ffmpeg-full}/bin/ffprobe -subsong all "$@"
  '';
  # airsonic-advanced-with-jdk17 = args@{ pkgs, ...}:
  #   import <nixpkgs/nixos/modules/services/misc/airsonic.nix>
  #     (args // { pkgs = pkgs // { jre8 = pkgs.jdk17; }; });
in {
  users.users.airsonic.createHome = lib.mkForce false;

  # disabledModules = ["services/misc/airsonic.nix"];
  # imports = [airsonic-advanced-with-jdk17];

  services = {
    airsonic = {
      enable = true;
      maxMemory = 1024;
      jre = pkgs.jdk17;
      home = "/srv/airsonic";
      transcoders = [
        "${pkgs.ffmpeg-full}/bin/ffmpeg"
        #"${pkgs.ffmpeg-full}/bin/ffprobe"
        "${ffprobe-subsong-wrapper}/bin/ffprobe"
      ];
    };

    nginx.virtualHosts."music.ancilla.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4040/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_redirect          http:// https://;
          proxy_read_timeout      600s;
          proxy_send_timeout      600s;
          proxy_buffering         off;
          proxy_request_buffering off;
          #proxy_set_header        Host $host;
          client_max_body_size    0;
        '';
      };
    };
  };
}
