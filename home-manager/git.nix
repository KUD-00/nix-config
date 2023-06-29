{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName  = "kud@nix";
    userEmail = "kasa7qi@gmail.com";
  };
}
