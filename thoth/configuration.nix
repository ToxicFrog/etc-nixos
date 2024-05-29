{ config, pkgs, lib, unstable, secrets, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.bluetooth.enable = true;

  users.users = secrets.thoth.users { inherit pkgs; };

  nix.settings.extra-substituters = [ "https://cache.lix.systems" ];
  nix.settings.trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thoth";
  networking.domain = "ancilla.ca";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraUpFlags = [
      "--login-server=https://headscale.ancilla.ca"
    ];
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  services.xserver.displayManager.defaultSession = "plasmawayland";
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "bex";
  };

  sound.enable = true;
  hardware.pulseaudio = lib.mkForce {
    enable = true;
    support32Bit = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkForce false;
  };

  programs.steam.enable = true;
  services.input-remapper.enable = true;
  virtualisation.waydroid.enable = true;
  environment.systemPackages = with pkgs; [
    unstable.alephone
    unstable.alephone-marathon unstable.alephone-durandal unstable.alephone-infinity
    appimage-run
    calibre
    crossfire-jxclient crossfire-editor
    digikam
    gargoyle
    unstable.gzdoom udb-editor
    love
    steam steam.run unstable.heroic unstable.gamescope protonup-ng protonup-qt # gog/epic
    syncthing qsyncthingtray
    unstable.prusa-slicer
    vscode
    vulkan-loader vulkan-tools
    yakuake
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
