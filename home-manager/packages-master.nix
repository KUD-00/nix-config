{ config, lib, pkgs, pkgs-master, ... }:

{
  home.packages = with pkgs-master; [
    rustc
  ];
}
