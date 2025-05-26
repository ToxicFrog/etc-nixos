{ config, pkgs, unstable, inputs, ... }:

{
  # nixpkgs.config.packageOverrides = pkgs: {
  #   steam = pkgs.steam.override {
  #     extraPkgs = pkgs: with pkgs; [
  #       libpng  # for dead cells
  #       # pango harfbuzz libthai # previously needed
  #     ];
  #   };
  # };

  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # for gaming
    jre scummvm wine # itch itgmania
    steam.run steam
    #unstable.heroic.override { mesa = pkgs.mesa; }) # override for Mesa bug when stable/unstable Mesa are mixed in the same package
    heroic
    unstable.gamescope protonup-ng protonup-qt # gog/epic
    fluidsynth soundfont-fluid
    caffeine-ng # power control for retroarch
    antimicrox # controller support for keyboard-only games
    appimage-run # for gdlauncher
    drl
    opentyrian
    unstable.knossosnet
    scanmem
    # golly
    unstable.gzdoom udb-editor doomrunner
    crossfire-jxclient crossfire-gridarta
    unstable.alephone
    unstable.alephone-marathon unstable.alephone-durandal unstable.alephone-infinity
    unstable.alephone-pathways-into-darkness unstable.alephone-rubicon-x
    (retroarch.override {
      cores = with libretro; [
        dolphin mgba beetle-psx beetle-psx-hw bsnes-hd snes9x gambatte pcsx2 nxengine ppsspp mupen64plus
      ];})
    unstable.pcsx2
    # for dbgl
    swt dosbox gsettings-desktop-schemas
    # for exodos-ll
    unstable.dosbox-staging dialog
    # misc games
    quadrapassel ltris lbreakout2
    vulkan-tools vulkan-loader
    love
    #libsForQt5.phonon-backend-vlc
    #libsForQt5.phonon-backend-gstreamer gst-plugins-good gst-plugins-ugly
  ];
}
