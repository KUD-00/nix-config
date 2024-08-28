{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    bun
    nodePackages_latest.nodejs
    nodePackages_latest.pnpm
    nodePackages_latest.wrangler
  ]);
}
