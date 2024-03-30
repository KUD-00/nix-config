{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.neovim.plugins = with pkgs.vimPlugins; [
    nvim-tree-lua
    nvim-treesitter-parsers.v
  ];
}
