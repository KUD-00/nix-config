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
      pavucontrol
      qpwgraph
      google-chrome
      vscode
      beekeeper-studio
      drawio
      variety
  ]);
}
