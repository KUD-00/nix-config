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
      vlc
      vscode
      firefox
      slack
      calibre
      nyxt
      gitkraken
      teamviewer
      zulip
      evince

# tools
      ydotool
      swaybg
      waybar
      wttrbar
      wl-clipboard
      cliphist
      wireplumber
      grim
      indicator-sound-switcher
      slurp 
      fcitx5-chinese-addons
      syncthing
      hyphen
      tracker
      openrgb
      libsForQt5.polkit-kde-agent

# cli
      nitch
      yazi
      cool-retro-term
      atool
      ripgrep
      fd
      imagemagick
      joshuto
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
      kubernetes
      kubectl
      kind
      minikube
      kubectx
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

## rust
      rustc
      cargo
## nix
      nix-index
  ]) ++ (with pkgs.gnome; [ 
    nautilus
    zenity
    gnome-tweaks
    eog
    gvfs
    dconf-editor
  ]);
}
