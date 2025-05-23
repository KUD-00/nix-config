{ inputs, outputs, lib, config, pkgs, pkgs-stable, pkgs-master, hostname, ... }: {
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./environment.nix
    ./hypr.nix
    ./waybar.nix
    ./bash.nix
    ./kitty.nix
    ./starship.nix
    ./packages.nix
#    ./packages-stable.nix
#    ./packages-master.nix
    ./nvim.nix
    ./dunst.nix
    ./theme.nix
    ./rofi.nix
    ./scripts.nix
  ];

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      # outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {#   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true); # Workaround for https://github.com/nix-community/home-manager/issues/2942
    };
  };

  home = {
    username = "kud";
    homeDirectory = "/home/kud";
  };

  programs = {
    home-manager.enable = true;
    
    git = {
      enable = true;
      userName  = "kud@nix";
      userEmail = "kasa7qi@gmail.com";
      extraConfig = {
        http.postBuffer = 524288000;
        credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
      };
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.05";  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}

