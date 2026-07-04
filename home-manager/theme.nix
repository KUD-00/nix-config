{ config, lib, pkgs, ... }:

{
  gtk = {
    enable = true;

    iconTheme = {
      name = "Yaru-magenta-dark";
      package = pkgs.yaru-theme;
    };

    theme = {
      name = "Ant";
      package = pkgs.ant-theme;
    };

    gtk4.theme = config.gtk.theme;

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };
}
