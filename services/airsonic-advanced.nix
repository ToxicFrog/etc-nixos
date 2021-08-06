args @ { pkgs, ... }:

let
  pkgs-with-jdk11 = pkgs // { jre8 = pkgs.jdk11; };
  args-with-jdk11 = args // { pkgs = pkgs-with-jdk11; };
in
import <nixpkgs/nixos/modules/services/misc/airsonic.nix> args-with-jdk11
