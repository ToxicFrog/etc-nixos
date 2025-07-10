# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, lib, unstable, secrets, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users = (secrets.users { inherit config pkgs lib; }).durandal;

  networking = {
    hostName = "durandal";
    domain = "ancilla.ca";
    networkmanager.enable = true;
    firewall.enable = false;
    hostId = "c4262b23";
  };

  # services.displayManager.autoLogin = {
  #   enable = true;
  #   user = "bex";
  # };

  programs.steam.enable = true;
  virtualisation.waydroid.enable = false;

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      input-overlay
      obs-pipewire-audio-capture
      obs-vkcapture
      waveform
      wlrobs
    ];
  };

  environment.systemPackages = with pkgs; [
    antimicrox  # controller support for kb-only games
    unstable.archipelago
    caffeine-ng
    chromium # for rando nights over discord
    crossfire-jxclient crossfire-gridarta
    digikam
    dosbox unstable.dosbox-staging dialog
    fluidsynth soundfont-fluid
    unstable.gzdoom udb-editor doomrunner unstable.sladeUnstable
    #untable.heroic.override { mesa = pkgs.mesa; }) # override for Mesa bug when stable/unstable Mesa are mixed in the same package
    # This is needed for Timespinner rando to work when launched from Heroic.
    (writeShellScriptBin "heroic" ''
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${mono}/lib"
      mkdir -p ~/.config/.mono/new-certs
      rm -f ~/.config/.mono/new-certs/Trust
      ln -s "${mono}/share/.mono/new-certs/Trust" ~/.config/.mono/new-certs/Trust
      exec ${heroic}/bin/heroic
    '')
    unstable.gamescope protonup-ng protonup-qt # gog/epic
    gimp
    itch
    unstable.knossosnet  # Freespace
    love
    unstable.pcsx2
    randovania
    (retroarch.override {
      cores = with libretro; [
        dolphin mgba beetle-psx beetle-psx-hw bsnes-hd gambatte pcsx2 nxengine ppsspp mupen64plus
        bsnes-mercury-performance # for Archipelago
      ];})
    unstable.rpcs3 unstable.ryujinx
    scanmem  # cheats
    scummvm
    steam.run steam
    syncthing qsyncthingtray
    vscode
    wine
    yakuake
  ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      plasma6Support = true;
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-anthy fcitx5-mozc
      ];
    };
  };

  security.rtkit.enable = true;
  services.pipewire.enable = true;

  environment.etc."wireplumber/main.lua.d/99-disable-suspend.lua".text = ''
    table.insert(alsa_monitor.rules,
      {
        matches = {{{ "node.name", "matches", "alsa_output.*" }}};
        apply_properties = {
          ["dither.noise"] = 2;
          ["node.pause-on-idle"] = false;
          ["session.suspend-timeout-seconds"] = 0;
        }
      }
    )
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
