# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "timelapse"; # Define your hostname.
  networking.domain = "ancilla.ca";
  networking.wireless = {
    enable = true;  # Enables wireless support via wpa_supplicant.
    networks."Traxus IV" = { psk = "basketofspiders"; };
    interfaces = ["wlan0"];
  };

  hardware.enableRedistributableFirmware = true;

  nixpkgs.overlays = [
    (self: super: {
      firmwareLinuxNonfree = super.firmwareLinuxNonfree.overrideAttrs (old: {
        version = "2020-12-18";
        src = pkgs.fetchgit {
          url =
            "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
          rev = "b79d2396bc630bfd9b4058459d3e82d7c3428599";
          sha256 = "1rb5b3fzxk5bi6kfqp76q1qszivi0v1kdz1cwj2llp5sd9ns03b5";
        };
        outputHash = "1p7vn2hfwca6w69jhw5zq70w44ji8mdnibm1z959aalax6ndy146";
      });
    })
  ];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.timelapse = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA1vSpVbx5fVJIK502nZl2ddk9VIbo7H06Up6eqk5brnFJG06gn9RtztFpIZaSUmDtdIlb9X0wSGGoiWGkwithc/79SvulOZD1X1DgNjjxIgXnNR1qlXm5ZjqjbWvL2NPKmyO7BP7IA1B0YkEj6sIQL7FWi7uIV/04qI/xSKPtGbhFtS+qoskv5p1GwhlJOuk3zKHJ7tue/CIiT8HEBl3OSGlQazItPOjLf4jkw7aE6Bl5pU8vbruUVry/SrXBo4AQw80H5Np6GCPrGj5eCDmsT4E+e5SZmaF414ih9YL6dtGXWWI2k13su9A3/OZ+UNx6Oz3iEoarkBPpap9VnhrbRQ== rebecca@thoth.ancilla.ca"
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8yJCgbZVMxI5mfzhRqPl5aP3yEksIrzCAf8IdoM38mxJRyu8fFxOu2iRiNHSUAWvFMvsslhs59DKMMoAdNy2qTIglpt4HAKM5TahYt88UmewbdEniLF3MhUlNwa0rAzFwB4V/X++0kBb5AmAYpESibGqPnpHqPMeMZeJHCP21GjhSduhS/rtdVv9wgm7Ng6Ezsh4Bxo/hPO9T4RmhMGV0V6JyFePBzQpvfWXlgiAWVpkRntFY3Io6+m3l0PBafqe+a2du6C+CgFgBUqBoOwM4kDBON2t6dpyQ+DxnLYLfMMv+sAer+Ko+mrZG6NyzoyZH6kPLwP5Jt68KtBpsHBfKw== rebecca@ancilla.ancilla.ca"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZrTCPT15bmOjJgSu1Zd+w+5gePqbZUdGt+dX2oJgW0ilv7PcAi+qm0F39KufifLCMazRyiLeQhbY8TfOWaXUKMxH4Y618fiRXNIvnAMt0WyZQhsnGf7J+z5BtclQnzn1uU4a2V+qAVgGJ/cF6DXaFvg1QYrQLSsqKsz4AXrpKANtOU2f0SEjDLXUpKVJf3nILa9PeCyovhH4a9BSkJ0+gfFPAMG29qjNnCjOOg7mgSVz1XiKWNBs5uAMjJSwWzVhFrfb9Q5w/X9kFFd74VQwjg0ldr+xcGq1TWfmlhFyKvnHjr8SKG0+eyehwg9GDUzs09dZmbXERxA3smrUi4w2B root@ancilla.ancilla.ca"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nano
    xawtv
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

