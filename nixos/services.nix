{ inputs, config, lib, pkgs,  ... }:

{
  services = {
    syncthing = {
      enable = true;
      user = "kud";
      configDir = "/home/kud/.config/syncthing";
      settings.folders = {
        "Wallpapers" = {
          path = "/home/kud/Documents/wallpapers";
          devices = [
            "Mikan"
            "Lain"
          ];
        };
      };
      settings.devices = {
        Mikan = {
          id = "ELXVWL2-WB7MJLI-GGME6VK-KJGRO6T-5NH4EVL-3NQAS5I-M2CVCD5-7FCGYQ6";
          autoAcceptFolders = true;
          introducer = true;
        };
        Lain = {
          id = "";
          autoAcceptFolders = true;
          introducer = true;
        };
      };
    };

    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hydra = {
      enable = false;
      hydraURL = "http://localhost:3020";
      notificationSender = "hydra@localhost";
      buildMachinesFiles = [];
      useSubstitutes = true;
    };

    flatpak.enable = true;

    gvfs.enable = true;

    upower.enable = true;
  };
}
