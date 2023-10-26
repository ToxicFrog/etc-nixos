# Packages that should be installed on all machines.

{ config, pkgs, lib, unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    binutils  # for strings and nm
    btop
    unstable.chezmoi
    dos2unix
    dtrx
    ffmpeg-vgz
    file
    findutils
    unstable.fortune-kind
    gitFull git-crypt git-secrets
    gnumake
    htop
    jre
    lsd
    luajit
    man-pages
    micro
    nb
    ncdu
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
    wget
    zip
  ];
}
