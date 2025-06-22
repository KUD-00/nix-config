{ inputs, config, lib, pkgs,  ... }:

{
  imports = [
    ./font.nix
    ./services.nix
  ];

  boot.loader = {
    timeout = 1;
    efi.canTouchEfiVariables = true;
    systemd-boot = { 
      enable = true;
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
    inputMethod = {
      type = "fcitx5";
      enable = true;
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
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "kud" ];


  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
            }).fd];
      };
    };
  };

  services.pulseaudio = {
    enable = false;
    support32Bit = true;
  };

  hardware = {
    bluetooth.enable = true;
    graphics.enable32Bit = true;
  };

  users.users.kud = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "libvirtd" ]; # Enable ‘sudo’ for the user.
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
    sops

    gnomeExtensions.unite
    # FHS
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
     pkgs.buildFHSEnv (base // {
       name = "fhs";
       targetPkgs = pkgs: (
         # pkgs.buildFHSEnv 只提供一个最小的 FHS 环境，缺少很多常用软件所必须的基础包
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

  # programs = {
  #   hyprland.enable = true;
  # };

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

  environment.gnome.excludePackages = (with pkgs; [
    gnome-music
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    gnome-shell
    gnome-software
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-sudoku
    gnome-maps

    gnome-calendar
    simple-scan
    gnome-user-share
    yelp
    gnome-text-editor
    gnome-connections
    epiphany
    ]);

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
}
