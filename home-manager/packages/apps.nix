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
      pkgs-master.windsurf
      pkgs-master.code-cursor-fhs
      pkgs-master.claude-code
      affine
      drawio
      variety
      lens
  ]);
}
