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
      drawio
      variety
      lens
  ]);
}
