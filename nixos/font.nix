{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    twemoji-color-font
  ];
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-extra
      noto-fonts-emoji
      nerdfonts
      twemoji-color-font
      fira-code
      fira-code-symbols
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        sansSerif = [
          "Noto Sans CJK JP"
          "DejaVu Sans"
        ];

        serif = [
          "Noto Serif JP"
          "DejaVu Serif"
        ];
      };
    };
  };
}
