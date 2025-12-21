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
      flacon
      pkgs-master.antigravity-fhs
      pkgs-master.warp-terminal
      # pkgs-master.kiro-fhs  # DNS resolution fails in Nix sandbox
  ]);
}
