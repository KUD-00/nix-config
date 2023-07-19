{ config, lib, pkgs, pkgs-stable, ... }:

{
  home.packages = with pkgs-stable; [
    zoom-us
    google-chrome
  ];
}
