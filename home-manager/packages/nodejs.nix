{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    bun
    deno
    nodePackages_latest.nodejs
    nodePackages_latest.pnpm
    nodePackages_latest.wrangler
  ]);
}
