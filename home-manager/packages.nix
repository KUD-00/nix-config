{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
      # apps
      qq
      steam
      obs-studio
      vlc
      telegram-desktop
      vscode
      firefox
      chromium
      slack

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
      unrar
      lazygit
      tree-sitter


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
