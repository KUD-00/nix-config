{ inputs, config, pkgs, ... }:

{
  imports =
    [
      ./lain-hardware-configuration.nix
      ./common-configuration.nix
    ];

  boot = {
    loader = {
      systemd-boot = { 
        configurationLimit = 6;
      };
    };
    kernelParams = [
      "i915.enable_psr=0"
      "reboot=bios"
      # 虚拟显示器 EDID (iPad Pro 11")
      "drm.edid_firmware=DP-2:edid/ipad-pro-11.bin"
      "video=DP-2:e"
    ];
  };

  hardware = {
    graphics = {
      # Enable OpenGL
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        nvidia-vaapi-driver
      ];
    };

    # 虚拟显示器 EDID firmware
    firmware = [
      (pkgs.runCommand "edid-ipad-firmware" {} ''
        mkdir -p $out/lib/firmware/edid
        cp ${./ipad-pro-11.bin} $out/lib/firmware/edid/ipad-pro-11.bin
      '')
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # services.k0s = {
  #   enable      = true;                  # 启用 k0s
  #   package    = inputs.k0s-nix
  #                  .packages."${pkgs.system}"
  #                  .k0s;                # 拿到 k0s-nix flake 构建出的二进制
  #   dataDir     = "/var/lib/k0s";        # 默认数据目录
  #
  #   role = "controller+worker";
  #
  #   # The first controller to bring up does not have a join token,
  #   # it has to be flagged with "isLeader".
  #   isLeader = true;
  #
  #   spec = {
  #     api = {
  #       # 绑定所有本地接口，或改成你控制节点的局域网 IP
  #       address = "192.168.2.105";
  #       # （可选）如果想改 API 端口，可额外设置 port, k0sApiPort 等
  #       port = 6443;
  #       sans    = [
  #         "127.0.0.1"            # localhost
  #         "localhost"
  #         "192.168.2.105"        # 控制节点局域网 IP（改成你的实际 IP）
  #         "kud.local"            # 控制节点的 DNS 名（如果有的话）
  #       ];
  #     };
  #
  #     # （可选）还可以声明存储后端，网络插件等
  #     storage = {
  #       type        = "etcd";
  #       etcd = {
  #         peerAddress = "127.0.0.1";
  #       };
  #     };
  #   };
  # };

  # K3s configuration
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--debug" # Optionally add additional args to k3s
  ];

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    8132
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  environment.systemPackages = with pkgs; [
  #   # Pulls the prebuilt k0s from the k0s-nix flake for your system
  #   inputs.k0s-nix.packages.${pkgs.system}.k0s
    cudaPackages.cuda_nvcc
  ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  }; 

  networking.hostName = "Lain";

  virtualisation.docker.daemon.settings = {
    data-root = "/develop/docker";
  };


# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05";

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

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
services.openssh.enable = true;
swapDevices = [
  {
    device = "/swapfile";
    size   = 96 * 1024;
  }
];

# Enable touchpad support (enabled default in most desktopManager).
# services.xserver.libinput.enable = true;
}

