# Packages that should be installed on all machines.

{ config, pkgs, lib, unstable, ... }:

{
  # Include terminfo files from all known terminals in the terminfo database,
  # even if they aren't installed. This means we'll handle them correctly if
  # someone using them logs in over telnet or ssh.
  environment.enableAllTerminfo = true;

  environment.systemPackages = with pkgs; [
    unstable.atuin
    binutils  # for strings and nm
    btop
    unstable.chezmoi
    csvkit
    dos2unix
    dtrx
    eza
    file
    findutils
    firefox
    unstable.fortune-kind
    gitFull git-crypt git-secrets gitui
    gnumake
    htop
    jre
    lsd # deprecated, remove later
    luajit
    man-pages
    micro
    nb
    ncdu
    unstable.nix-output-monitor
    p7zip
    posix_man_pages
    python3
    rlwrap
    sshfs sshfs-fuse
    stdmanpages
    taskwarrior
    tmux
    unrar
    unzip
    vivid
    wget
    xxd
    unstable.zig
    zip
  ];
}
