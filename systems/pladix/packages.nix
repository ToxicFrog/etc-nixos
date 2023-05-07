{ config, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        libpng  # for dead cells
      ];
    };
  };

  programs.steam.enable = true;
  programs.adb.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    # system tools
    zip unzip ncdu htop xscreensaver wget ark git
    # for gaming
    jre retroarchBare stepmania lutris scummvm wine itch
    steam.run steam
    fluidsynth soundfont-fluid
    caffeine-ng # power control for retroarch
    antimicroX # controller support for keyboard-only games
    appimage-run # for gdlauncher
    opentyrian
    gzdoom
    # for dbgl
    swt dosbox gsettings-desktop-schemas
    # for exodos-ll
    dosbox-staging dialog
    # misc games
    gnome.quadrapassel ltris lbreakout2
    # for media playback
    chromium ffmpeg-full
    vulkan-tools vulkan-loader
    vlc
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
