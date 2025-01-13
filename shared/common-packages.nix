# Packages that should be installed on all machines.

{ config, pkgs, lib, unstable, ... }:

{
  # Include terminfo files from all known terminals in the terminfo database,
  # even if they aren't installed. This means we'll handle them correctly if
  # someone using them logs in over telnet or ssh.
  environment.enableAllTerminfo = true;

  environment.systemPackages = with pkgs; [
    unstable.atuin
    bat bat-extras.batdiff bat-extras.batman bat-extras.batwatch bat-extras.batgrep
    # bat-extras.batpipe
    binutils  # for strings and nm
    btop
    unstable.chezmoi
    dos2unix
    drl
    dtrx
    eza
    file
    findutils
    unstable.fortune-kind
    gitFull git-crypt git-secrets gitui
    gnumake
    htop
    jre
    jq
    luajit
    lshw
    man-pages
    man-pages-posix
    micro
    minimodem
    nb
    ncdu
    nvd
    unstable.nix-output-monitor
    p7zip
    python3
    ripgrep
    rlwrap
    sshfs sshfs-fuse
    stdmanpages
    tmux
    tree
    unrar
    unzip
    usbutils
    wget
    xxd
    zip
  ];
}
