{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
      # apps
      steam
      obs-studio
      vlc
      vscode
      firefox
      slack
      google-chrome

      # tools
      swaybg
      waybar
      wl-clipboard
      cliphist
      wireplumber
      grim
      indicator-sound-switcher
      slurp
      fcitx5-chinese-addons

      # cli
      ripgrep
      fd
      imagemagick
      joshuto
      atuin
      exa
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

      ## C
      gccgo13

      ## web
      nodePackages.pnpm
      nodePackages_latest.vercel
      yarn
      nodejs

      ## rust
      rustc
      cargo
  ];
}
