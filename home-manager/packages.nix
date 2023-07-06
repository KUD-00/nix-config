{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
      # apps
      qq
      steam
      obs-studio
      zoom-us
      vlc
      telegram-desktop

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
      busybox

      # dev
      docker
      nodePackages.pnpm
      yarn
  ];
}
