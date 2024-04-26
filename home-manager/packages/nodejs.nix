{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    bun
    corepack_latest
    nodePackages_latest.nodejs
  ]);
}
