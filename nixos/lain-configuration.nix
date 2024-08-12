{ inputs, config, pkgs, ... }:

{
  imports =
    [
      ./lain-hardware-configuration.nix
      ./common-configuration.nix
    ];

  
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

  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
    };
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

