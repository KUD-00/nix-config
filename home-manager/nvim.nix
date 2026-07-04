{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
  };

  programs.neovim.plugins = with pkgs.vimPlugins; [
    nvim-tree-lua
    nvim-treesitter-parsers.v
  ];
}
