{ inputs, config, pkgs, ... }:

{
  imports =
    [
      # ./mikan-hardware-configuration.nix
      ./common-configuration.nix
    ];

  networking.hostName = "Mikan";

  system.stateVersion = "23.05";

}

