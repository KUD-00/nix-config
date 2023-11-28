{ inputs, config, pkgs, xremap-flake, ... }:

{
  imports = [
    ./mikan-hardware-configuration.nix
    ./common-configuration.nix
    xremap-flake.nixosModules.default
  ];
  
#TODO: move this to common-configuration
  environment.systemPackages = [
    inputs.home-manager.packages.${pkgs.system}.default
  ];

#TODO: move this to home-manager
  services.xremap = {
    userName = "kud";
    serviceMode = "user";
    config = {
      modmap = [
        {
          name = "Global";
          remap = {
            "CapsLock" = "Backspace";
            "Alt_R" = "Enter";
            "Super_L" = "Ctrl_R";
            "Ctrl_R" = "Super_L";
#            "Super" = "Ctrl_R";
#            "Ctrl_R" = "Super";
          };
        }
      ];
    };
  };

  networking.hostName = "Mikan";

  system.stateVersion = "23.05";
}

