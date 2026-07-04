# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  marcel = pkgs.callPackage ./marcel.nix { };
  kiro-cli = pkgs.callPackage ./kiro-cli.nix { };
  codex-switcher = pkgs.callPackage ./codex-switcher.nix { };
  grok-build = pkgs.callPackage ./grok-build.nix { };
  orca-ide = pkgs.callPackage ./orca-ide.nix { };
}
