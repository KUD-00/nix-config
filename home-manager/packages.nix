{ config, lib, pkgs, ... }:

{
  programs.atuin.enable = true;

  home.packages = (with pkgs; [
# apps
      cpu-x
      mission-center
      qq
      mpv
      steam
      obs-studio
      firefox
      slack
      calibre
      gitkraken
      zulip
      cool-retro-term
      zoom-us

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
      libsForQt5.polkit-kde-agent # seems not working
      polkit_gnome

# for nvim
      luajitPackages.luarocks-nix
      php83Packages.composer
      php
      corepack_21
      nodejs_21
      zulu17
      julia_18
      python3
      python311Packages.pip
      python311Packages.venvShellHook

# cli
## app
      syncthing
      yazi
## fun
      nitch
## tool
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
      nvtop-amd
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

### archives
      zip
      xz
      unzip
      p7zip
      unrar

#TODO: test to remove these
## For Docker-OSX
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
      jetbrains-toolbox
      gjs
      gtk4.dev
      libadwaita
      webkitgtk_6_0
      meson
      pkg-config
      gettext
      flatpak
      glib
      strace
      bcc

## kubernetes
      kubernetes
      kubectl
      kind
      minikube
      kubectx
      docker
## C
      gnumake
      gccgo13
      libcap.dev

## rust
      rustc
      cargo
## nix
      nix-index

## add some gnome packages
  ]) ++ (with pkgs.gnome; [ 
    nautilus
    zenity
    gnome-tweaks
    eog
    gvfs
    dconf-editor
  ]);
}
