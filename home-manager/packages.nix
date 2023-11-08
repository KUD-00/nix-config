{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
# apps
      imv
      mpv
      steam
      obs-studio
      vlc
      vscode
      firefox
      slack
      google-chrome
      calibre
      chromium
      nyxt
      gitkraken
      teamviewer
      zulip

# tools
      swaybg
      waybar
      wl-clipboard
      cliphist
      wireplumber
      grim
      indicator-sound-switcher
      slurp fcitx5-chinese-addons
      syncthing
      hyphen
      tracker

# cli
      atool
      ripgrep
      fd
      imagemagick
      joshuto
      atuin
      eza
      bat
      du-dust
      duf
      gh
      nvtop-amd
      neofetch
      zip
      xz
      unzip
      p7zip
      jq
      fzf
      glow
      glances
      tldr
      procs
      httpie
      curlie
      playerctl
      gping
      pciutils
      unrar
      lazygit
      tree-sitter
      gdb
      amdgpu_top
      radeontop
      openssl
      thttpd

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
      docker
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

## C
      gnumake
      gccgo13
      libcap.dev

## web
      nodePackages.pnpm
      nodePackages_latest.vercel
      yarn
      nodejs

## rust
      rustc
      cargo
## nix
      nix-index
  ];
}
