{ config, lib, pkgs, ... }:

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
      windsurf
      drawio
      variety
      lens
  ]);
}
