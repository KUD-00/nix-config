{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
      foliate
      mission-center
      qq
      mpv
      steam
      obs-studio
      firefox
      slack
      # calibre
      zoom-us
      pavucontrol
      qpwgraph
      google-chrome
      chromium
      lapce
      vscode
      freac
      beekeeper-studio
      zed-editor
      android-studio
      # wechat-uos
  ]);
}
