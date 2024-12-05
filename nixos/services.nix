{ inputs, config, lib, pkgs,  ... }:

{
  imports = [
    # ./kubernetes.nix
  ];

  # sops.defaultSopsFile = ../secrets.enc.yaml;
  # sops.age.keyFile = "/home/kud/.config/sops/age/keys.txt";

  # sops.secrets.cloudflared_creds = {
  #   owner = "cloudflared";
  #   group = "cloudflared";
  #   mode = "0400";
  # };
  services = {
    tailscale.enable = true;
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
        "Books" = {
          path = "/home/kud/Documents/READ_NOW";
          devices = [
            "Mikan"
            "Lain"
          ];
        };
        "Sharing" = {
          path = "/home/kud/Documents/sharing";
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
          id = "NORNEXR-KAIUZUJ-2F4YC6M-RLEYOWE-D75RFYM-J4SWQJJ-BTPABV7-TF77VAJ";
          autoAcceptFolders = true;
          introducer = true;
        };
      };
    };

    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    gvfs.enable = true;

    upower.enable = true;

    fwupd.enable = true; # a simple daemon allowing you to update some devices' firmware, including UEFI for several machines. 
  };
}
