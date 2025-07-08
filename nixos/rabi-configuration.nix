{ inputs, config, pkgs, ... }:

{
  imports = [
    ./rabi-hardware-configuration.nix
    ./common-configuration.nix
    inputs.xremap-flake.nixosModules.default
  ];

  boot.loader = {
    systemd-boot = { 
      configurationLimit = 3;
    };
  };
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
            "Alt_L" = "Ctrl_R";
          };
        }
      ];
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
      size   = 16 * 1024;
    }
  ];

  # environment.systemPackages = with pkgs; [
  #   iio-sensor-proxy
  # ];

  hardware.sensor.iio.enable = true;

  networking.hostName = "Rabi";

  system.stateVersion = "24.11";
}
