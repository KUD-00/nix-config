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
    pkgs.fcitx5-pinyin-moegirl
  ];

  # services.tlp.enable = true;

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
            "Super_L" = "Ctrl_L";
            "Ctrl_R" = "Super_L";
          };
        }
      ];
    };
  };

  networking.hostName = "Mikan";

  system.stateVersion = "23.05";
}

