{ config, lib, pkgs, ... }:

{
  imports = [
    ./packages/go.nix
    ./packages/apps.nix
    ./packages/nodejs.nix
    ./packages/hyprland.nix
  ];

  programs.atuin.enable = true;

  home.packages = (with pkgs; [

# for nvim
      luajitPackages.luarocks-nix
      php83Packages.composer
      php
      zulu17

      python3
      python311Packages.pip
      python311Packages.venvShellHook

# cli
      v2ray
      v2raya
      dae
      innoextract
      yazi
      nitch
      wine64
      winetricks
      soundconverter
      kdiskmark
      pstree
      libcamera
      xdg-utils
      powerstat
      libnotify
      wget
      easyeffects
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
      nvtopPackages.amd
      amdgpu_top
      jq
      glow
      glances
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
      openssl
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
      bison
      iptables
      edk2
      exiftool

# dev
      cmake
      gjs
      ninja
      jetbrains-toolbox
      gjs
      gtk4
      gtk3
      libadwaita
      webkitgtk_6_0
      meson
      pkg-config
      gettext
      flatpak
      glib
      strace
      bcc

      kubernetes
      kubectl
      kind
      minikube
      kubectx
      docker
      awscli2
      terraform

      gnumake
      gccgo13
      libcap.dev

      rustc
      cargo

      nix-index

## add some gnome packages
      ]) ++ (with pkgs.gnome; [ 
        gnome-keyring
        gnome-disk-utility
        nautilus
        zenity
        gnome-tweaks
        eog
        gvfs
        dconf-editor
      ]);
}
