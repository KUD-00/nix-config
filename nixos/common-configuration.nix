{ inputs, config, lib, pkgs,  ... }:

{
  imports = [
    ./font.nix
    ./services.nix
  ];

  boot.loader = {
    timeout = 0;
    efi.canTouchEfiVariables = true;
    systemd-boot = { 
      enable = true;
      configurationLimit = 3;
    };

  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    initrd.kernelModules = [ "acpi_call" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "kud" ];
    substituters = [ "https://ezkea.cachix.org" ];
    trusted-public-keys = [ "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI=" ];
  };

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  security.rtkit.enable = true;

  security.polkit.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-mozc
      ];
    };
  };

  virtualisation.docker = {
    enable = true;
    extraOptions = "--data-root /develop/docker";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  hardware = {
    pulseaudio.enable = false;
    bluetooth.enable = true;
    graphics = {
      extraPackages = with pkgs; [
        amdvlk
      ];

      # For 32 bit applications Only available on unstable
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
  };

  users.users.kud = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    initialPassword = "seki123";
  };

  environment.systemPackages = with pkgs; [
    # custom packages(for nixpkgs maintain)
    marcel

    # basic tools
    bluez

    # basic dev
    kitty

    # secret managment
    inputs.agenix.packages."${system}".default

    gnomeExtensions.unite
    # FHS
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
     pkgs.buildFHSUserEnv (base // {
       name = "fhs";
       targetPkgs = pkgs: (
         # pkgs.buildFHSUserEnv 只提供一个最小的 FHS 环境，缺少很多常用软件所必须的基础包
         # 所以直接使用它很可能会报错
         #
         # pkgs.appimageTools 提供了大多数程序常用的基础包，所以我们可以直接用它来补充
         (base.targetPkgs pkgs) ++ [
           pkg-config
           ncurses
           fuse3
           # 如果你的 FHS 程序还有其他依赖，把它们添加在这里
         ]
       );
       profile = "export FHS=1";
       runScript = "bash";
       extraOutputsToInstall = ["dev"];
     }))
  ];

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  programs = {
    hyprland.enable = true;
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  environment.gnome.excludePackages = (with pkgs.gnome; [
    gnome-music
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
}
