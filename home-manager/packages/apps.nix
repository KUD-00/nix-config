{ config, lib, pkgs, pkgs-master, ... }:

{
  home.packages = (with pkgs; [
      foliate
      qq
      mpv
      steam
      obs-studio
      firefox
      google-chrome
      vscode
      pkgs-master.windsurf
      pkgs-master.code-cursor-fhs
      affine
      drawio
      variety
      lens
  ]);
}
