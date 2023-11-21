{ inputs, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader = {
    efi.canTouchEfiVariables = true;

    systemd-boot = { 
      enable = true;
      configurationLimit = 5;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "amdgpu" ];
  
  fileSystems = {
    "/data" = {
      device = "/dev/disk/by-uuid/f27a2b4c-6e7b-4ad0-86d0-6d79f1799a64";
      fsType = "ext4";
    };

    "/develop" = {
      device = "/dev/disk/by-uuid/19295e62-a0d0-4034-a38a-ffc84a9ccc89";
      fsType = "ext4";
    };
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

  networking.hostName = "Lain";

  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  time.timeZone = "Asia/Tokyo";

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

  sound.enable = true;

  security.rtkit.enable = true;

  hardware = {
    pulseaudio.enable = false;
    bluetooth.enable = true;
    opengl = {
      driSupport = true;
      driSupport32Bit = true;   # For 32 bit applications

      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
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
    # basic tools
    rofi-wayland-unwrapped # app launcher
    cinnamon.nemo-with-extensions # file browser
    blueman
    bluez
    qpwgraph

    # basic dev
    git
    kitty

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
           # 如果你的 FHS 程序还有其他依赖，把它们添加在这里
         ]
       );
       profile = "export FHS=1";
       runScript = "bash";
       extraOutputsToInstall = ["dev"];
     }))
  ];

  fonts.packages= with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    nerdfonts
    font-awesome
  ];

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  programs.hyprland.enable = true;
  services = {
    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    hydra = {
      enable = false;
      hydraURL = "http://localhost:3020";
      notificationSender = "hydra@localhost";
      buildMachinesFiles = [];
      useSubstitutes = true;
    };

    flatpak.enable = true;
  };

  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05";

  # --------------------------------------------------------------------------
  # --------------------------------------------------------------------------
  # virtualisation = {
  #   waydroid.enable = true;
  #   lxd.enable = true;
  # };
  
  # --------------------------------------------------------------------------
  # --------------------------------------------------------------------------
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  # services.atuin.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}

