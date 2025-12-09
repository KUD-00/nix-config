# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  marcel = pkgs.callPackage ./marcel.nix { };
  happy-coder = pkgs.callPackage ./happy-coder.nix { };
  kiro-cli = pkgs.callPackage ./kiro-cli.nix { };
}
