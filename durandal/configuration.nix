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

  users.users = {
    root = (secrets.thoth.users { inherit pkgs; }).root;
    bex = (secrets.thoth.users { inherit pkgs; }).bex // { createHome = true; };
  };
  networking = {
    hostName = "durandal";
    domain = "ancilla.ca";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "bex";
  };

  programs.steam.enable = true;
  virtualisation.waydroid.enable = false;

  environment.systemPackages = with pkgs; [
    # digikam
    syncthing qsyncthingtray
    vscode
    yakuake
  ];

  # TODO:
  # - see if just adding the extra plugins to alsa-plugins works
  # - if not, build it as a separate package (so we don't rebuild the world) and
  #   then manually add the a52 sink in alsa extraconfig
  sound.enable = true;
  sound.extraConfig = ''
    pcm_type.a52 {
      lib "${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_pcm_a52.so"
    }

    pcm.spdif51 {
      type a52
      card 1
      slavepcm "hw:1,1"
      channels 6
      rate 48000
    }

    ${builtins.readFile "${pkgs.alsa-plugins}/share/alsa/alsa.conf.d/60-a52-encoder.conf"}
  '';
  # hardware.pulseaudio = lib.mkForce {
  #   enable = true;
  #   support32Bit = true;
  # };
  security.rtkit.enable = true;
  services.pipewire.enable = true;

  # environment.etc."alsa/conf.d".source = "${pkgs.alsa-plugins-full}/share/alsa/alsa.conf.d/";
  nixpkgs.overlays = [
    (self: super: {
      alsa-plugins = super.alsa-plugins.overrideAttrs (old: rec {
        buildInputs = old.buildInputs ++ (with self; [ libsamplerate ffmpeg ]);
      });
    })
  ];

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

