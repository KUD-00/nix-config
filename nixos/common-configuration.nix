{ inputs, config, lib, pkgs,  ... }:

{
  imports = [
    ./font.nix
    ./services.nix
    inputs.vscode-server.nixosModules.default
  ];

  # VSCode Server 自动 patch
  services.vscode-server = {
    enable = true;
    installPath = [
      "$HOME/.vscode-server"
      "$HOME/.vscode/cli/servers"  # VSCode CLI/Tunnel 模式
    ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    # 启用 CUDA 支持以使用 NVENC 硬件编码
    package = pkgs.sunshine.override { cudaSupport = true; };
    settings = {
      encoder = "nvenc";
      # DP-2 phantom display (iPad Pro 11 EDID). See `Monitor N is ...` lines in sunshine.log.
      output_name = "1";
    };
  };

  # uinput 权限（解决鼠标问题）
  users.groups.uinput = {};
  
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # 确保 uinput 模块加载
  # ntsync: NT 同步原语驱动,Wine/Proton 用它替代 esync/fsync,游戏性能更好
  # tcp_bbr: BBR 拥塞控制(默认是模块,需显式加载)
  boot.kernelModules = [ "uinput" "ntsync" "tcp_bbr" ];

  boot.loader = {
    timeout = 10;
    efi.canTouchEfiVariables = true;
    systemd-boot = { 
      enable = true;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    initrd.kernelModules = [ "acpi_call" ];
    kernel.sysctl."kernel.sysrq" = 1;
    # 提高内存映射上限到 SteamOS 默认值,修复部分现代游戏的崩溃/卡顿
    kernel.sysctl."vm.max_map_count" = 2147483642;
    # BBR 拥塞控制 + fq 队列,改善串流/远程访问的吞吐与延迟
    kernel.sysctl."net.core.default_qdisc" = "fq";
    kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    max-jobs = "auto"; # 并行构建多个 derivation
    cores = 0;         # 每个构建用满所有 CPU 核心
    trusted-users = [ "root" "kud" ];
    substituters = [ "https://ezkea.cachix.org" ];
    trusted-public-keys = [ "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI=" ];
  };

  networking.networkmanager = {
    enable = true;
    # 在 Tailscale DNS 之前插入公共 DNS，解决 Nix 沙箱问题
    insertNameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  time.timeZone = "Asia/Tokyo";

  security.rtkit.enable = true;

  security.polkit.enable = true;

  i18n = {
    inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        qt6Packages.fcitx5-chinese-addons
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

  # virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "kud" ];


  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
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
    extraGroups = [ "wheel" "docker" "libvirtd" "input" "video" "uinput" ]; # Enable ‘sudo’ for the user.
  };

  environment.systemPackages = with pkgs; [
    # custom packages(for nixpkgs maintain)
    marcel

    # basic tools
    bluez
    bubblewrap

    # basic dev
    kitty

    # secret managment
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
    sops

    gnomeExtensions.unite
    gnome-randr
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

  programs = {
    hyprland.enable = true;
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      curl
      openssl
      libsecret

      # Runtime libraries for npm-distributed Electron/Chromium binaries.
      glib
      nss
      nspr
      atk
      at-spi2-core
      cups
      dbus
      cairo
      gtk3
      pango
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxrender
      libxkbcommon
      libxshmfence
      libgbm
      mesa
      libdrm
      expat
      systemd
      alsa-lib
    ];
  };

  # 游戏相关
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;            # Steam Remote Play
    dedicatedServer.openFirewall = true;       # 本地专用服务器
    localNetworkGameTransfers.openFirewall = true; # 局域网游戏传输
    gamescopeSession.enable = true;            # gamescope 会话
    extraCompatPackages = with pkgs; [ proton-ge-bin ]; # Proton-GE,ntsync 支持最佳
  };

  # 游戏时自动切 CPU performance 调度 / GPU 性能档,退出自动恢复
  programs.gamemode.enable = true;

  # Valve Wayland 微合成器(缩放/限帧/FSR/HDR)
  programs.gamescope.enable = true;

  # 禁止系统自动休眠/挂起（远程访问时不被打断）
  services.displayManager.gdm.autoSuspend = false;

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
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
