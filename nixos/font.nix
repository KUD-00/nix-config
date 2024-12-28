{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    twemoji-color-font
  ];
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-extra
      noto-fonts-emoji
      twemoji-color-font
      fira-code
      fira-code-symbols
      nerd-fonts.jetbrains-mono
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        sansSerif = [
          "Noto Sans CJK SC"
          "Noto Sans CJK JP"
          "DejaVu Sans"
        ];

        serif = [
          "Noto Serif CJK SC"
          "Noto Serif CJK JP"
          "DejaVu Serif"
        ];

        monospace = [
          "Noto Sans Mono CJK SC"
        ];

        emoji = [
          "Twitter Color Emoji"
        ];
      };
    };
  };
}
