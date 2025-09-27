{ config, lib, pkgs, pkgs-master, ... }:

{
  imports = [
    ./packages/go.nix
    ./packages/apps.nix
    # ./packages/nodejs.nix
    # ./packages/hyprland.nix
    ./packages/docker.nix
  ];

  programs.atuin.enable = true;

  home.packages = (with pkgs; [
      pkgs-master.codex
      swaybg
      waypaper
      # neohtop
      wrangler
      tailscale
      yt-dlp-light
      ngrok

# for nvim
      luajitPackages.luarocks-nix
      # php83Packages.composer
      php
      zulu17

      python3
      python311Packages.pip
      python311Packages.venvShellHook

      go-task
      cloudflared
      buf
      age
      docker-machine-kvm2
      virtualbox
      cloc

      innoextract
      # yazi
      wine64
      winetricks
      libcamera
      xdg-utils
      powerstat
      libnotify
      pamixer
      light
      brightnessctl
      atool
      ripgrep
      fd
      imagemagick
      eza
      bat
      du-dust
      duf
      gh
      nvtopPackages.nvidia 
      jq
      glow
      tldr
      procs
      httpie
      curlie
      playerctl
      gping
      pciutils
      lazygit
      tree-sitter
      gdb
      pango
      thttpd

      zip
      xz
      unzip
      p7zip
      unrar

      qemu
      libvirt
      dnsmasq
      virt-manager
      bridge-utils
      flex
      iptables
      edk2

# dev
      imhex
      jetbrains-toolbox

      terraform

      rustc
      cargo

      nix-index

## add some gnome packages
      gnome-keyring
      gnome-disk-utility
      nautilus
      zenity
      gnome-tweaks
      eog
      gvfs
      # dconf-editor
  ]);
}
