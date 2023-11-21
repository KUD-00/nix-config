{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.neovim.plugins = [
    pkgs.vimPlugins.nvim-tree-lua
    pkgs.vimPlugins.nvim-treesitter-parsers.v
  ];
}
