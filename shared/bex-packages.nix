# Packages particular to Bex's interactive machines that are unlikely to be
# generally useful.
# In practice this means ancilla, thoth, and durandal.

{ config, pkgs, lib, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    csvkit
    expect
    inetutils # telnet
    pandoc # nb export
    poppler_utils # pdf manipulators
    unstable.taskwarrior3
    vivid
    unstable.zig
  ];
}
