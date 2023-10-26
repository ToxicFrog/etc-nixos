{ config, pkgs, unstable, inputs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        libpng  # for dead cells
        # pango harfbuzz libthai # previously needed
      ];
    };
  };

  programs.steam.enable = true;
  programs.adb.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    # system tools
    xscreensaver ark
    # for gaming
    jre stepmania lutris scummvm wine itch
    steam.run steam
    fluidsynth soundfont-fluid
    caffeine-ng # power control for retroarch
    antimicroX # controller support for keyboard-only games
    appimage-run # for gdlauncher
    opentyrian
    gzdoom
    crossfire-jxclient crossfire-editor
    unstable.alephone
    unstable.alephone-marathon unstable.alephone-durandal unstable.alephone-infinity
    unstable.alephone-pathways-into-darkness unstable.alephone-rubicon-x
    (retroarch.override {
      cores = with libretro; [
        dolphin mgba beetle-psx beetle-psx-hw bsnes snes9x gambatte pcsx2 nxengine ppsspp mupen64plus
      ];})

    # for dbgl
    swt dosbox gsettings-desktop-schemas
    # for exodos-ll
    unstable.dosbox-staging dialog
    # misc games
    gnome.quadrapassel ltris lbreakout2
    chromium  # ffmpeg/libavcodec is part of the common package set
    vulkan-tools vulkan-loader
    #libsForQt5.phonon-backend-vlc
    #libsForQt5.phonon-backend-gstreamer gst-plugins-good gst-plugins-ugly
    # for fun
    fortune
    # for android stuff
    scrcpy
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-11.5.0"  # not sure what needs this. TODO: audit
  ];
}
