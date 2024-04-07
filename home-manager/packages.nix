{ config, lib, pkgs, ... }:

{
  imports = [
    ./packages/go.nix
    ./packages/apps.nix
  ];

  programs.atuin.enable = true;

  home.packages = (with pkgs; [
# desktop
      rofi-wayland
      wev # test input event
      wtype
      swaybg
      waybar
      wttrbar # weather for waybar
      wl-clipboard
      cliphist
      wireplumber
      grim
      indicator-sound-switcher # seems not working
      slurp # select a region of screen in wayland
      fcitx5-chinese-addons
      tracker
      openrgb
      polkit_gnome

# for nvim
      luajitPackages.luarocks-nix
      php83Packages.composer
      php
      corepack_latest
      nodePackages_latest.nodejs
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

# dev
      ninja
      jetbrains-toolbox
      gjs
      gtk4.dev
      gtk3.dev
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
