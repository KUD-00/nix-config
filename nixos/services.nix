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

    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

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

    # 记录历史系统负载(CPU/内存/IO), 用 `sar -u` 看 CPU、`sar -r` 看内存、`sar -d` 看磁盘。
    # 数据存在 /var/log/sa/, 默认保留约一个月。
    sysstat = {
      enable = true;
      collect-frequency = "*:00/5"; # 每 5 分钟采样一次
      collect-args = "1 1 -S DISK"; # 顺便记录每块磁盘的 IO
    };
  };
}
