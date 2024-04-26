{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
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
      polkit_gnome
  ]);
}
