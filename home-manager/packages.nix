{ config, lib, pkgs, ... }:

let
  aagl-gtk-on-nix = import (builtins.fetchTarball {
      url = "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz";
      sha256 = "1bkycmk27nykiah9qicnh3q79zpaw00gsz2sw5hf554451swr6h0";
    }
  );
in
{
  home.packages = with pkgs; [
      aagl-gtk-on-nix.anime-game-launcher
      aagl-gtk-on-nix.anime-borb-launcher
      aagl-gtk-on-nix.honkers-railway-launcher
      aagl-gtk-on-nix.honkers-launcher
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
      syncthing

# cli
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
