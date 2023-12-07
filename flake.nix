{
  description = "kud's nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    xremap-flake.url = "github:xremap/nix-flake";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    agenix.url = "github:ryantm/agenix";

    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-doom-emacs, xremap-flake, nixos-hardware, berberman, agenix, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );
      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        Lain = nixpkgs.lib.nixosSystem {
        # system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ inputs.self.overlays.additions ];
            })
            ./nixos/lain-configuration.nix
            agenix.nixosModules.default
          ];
        };

        Mikan = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs xremap-flake; };
          modules = [
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ 
                inputs.self.overlays.additions
                inputs.berberman.overlays.default
              ];
            })
            ./nixos/mikan-configuration.nix
            nixos-hardware.nixosModules.lenovo-ideapad-slim-5 
            agenix.nixosModules.default
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "kud@Lain" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = {
            inherit inputs outputs nix-doom-emacs;
          };
          modules = [
            ./home-manager/home.nix
          ];
        };

        "kud@Mikan" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs outputs nix-doom-emacs;
          };
          modules = [
            ./home-manager/home.nix
          ];
        };
      };
    };
}
