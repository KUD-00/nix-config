{ config, lib, pkgs, pkgs-stable, ... }:

{
  home.packages = with pkgs-stable; [
    qq
    zoom-us
  ];
}
