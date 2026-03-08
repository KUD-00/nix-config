{ config, lib, pkgs, pkgs-master, inputs, ... }:

{
  imports = [
    ./packages/go.nix
    ./packages/apps.nix
    ./packages/nodejs.nix
    # ./packages/hyprland.nix
    ./packages/docker.nix
  ];

  programs.atuin.enable = true;

  programs.vscode = {
    enable = true;
  };

  home.packages = (with pkgs; [
      yazi
      opencode
      termius
      remmina
      gnome-monitor-config
      gnome-randr
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      swaybg
      waypaper
      # neohtop
      wrangler
      tailscale
      yt-dlp-light
      ngrok

# for nvim
      luajitPackages.luarocks-nix
      # php83Packages.composer
      php
      zulu17

      python3
      python3Packages.pip
      python3Packages.venvShellHook

      go-task
      cloudflared
      buf
      age
      # virtualbox
      cloc

      # innoextract
      # yazi
      wine64
      winetricks
      libcamera
      xdg-utils
      powerstat
      libnotify
#      pamixer
#      light
      brightnessctl
      atool
      ripgrep
      fd
      imagemagick
      eza
      bat
      dust
      duf
      gh
      # nvtopPackages.nvidia  # 暂时禁用：CUDA 依赖包 broken
      jq
      glow
      tldr
      procs
      httpie
      curlie
      playerctl
      gping
      pciutils
      lazygit
      tree-sitter
      gdb
      pango
      thttpd

      zip
      xz
      unzip
      p7zip
      unrar

      qemu
      libvirt
      dnsmasq
      virt-manager
      bridge-utils
      flex
      iptables
      edk2

# dev
      # imhex
      jetbrains-toolbox

      terraform

      rustc
      cargo

      nix-index
      (writeShellScriptBin "power-estimate" ''
        #!/usr/bin/env bash
        set -e
        shopt -s nullglob

        baseline=30
        if [ -n "$BASELINE_W" ]; then
          baseline="$BASELINE_W"
        fi

        rapl="''${RAPL_PATH:-}"
        if [ -z "$rapl" ]; then
          for base in /sys/class/powercap /sys/devices/virtual/powercap; do
            for dir in "$base"/intel-rapl:*; do
              [ -r "$dir/energy_uj" ] || continue
              if [ -r "$dir/name" ]; then
                name="$(cat "$dir/name")"
                case "$name" in
                  package-*) rapl="$dir/energy_uj"; break 2 ;;
                esac
              fi
            done
          done
        fi
        if [ -z "$rapl" ]; then
          for base in /sys/class/powercap /sys/devices/virtual/powercap; do
            for file in "$base"/intel-rapl:*/energy_uj; do
              [ -r "$file" ] || continue
              rapl="$file"; break 2
            done
          done
        fi
        if [ -z "$rapl" ] || [ ! -r "$rapl" ]; then
          echo "RAPL not available. Try: ls /sys/class/powercap" >&2
          echo "Or set RAPL_PATH=/path/to/energy_uj" >&2
          exit 1
        fi

        nvidia_smi="$(command -v nvidia-smi || true)"
        if [ -z "$nvidia_smi" ] && [ -x /run/opengl-driver/bin/nvidia-smi ]; then
          nvidia_smi="/run/opengl-driver/bin/nvidia-smi"
        fi

        while true; do
          e1=$(cat "$rapl"); t1=$(date +%s%N)
          sleep 1
          e2=$(cat "$rapl"); t2=$(date +%s%N)

          cpu=$(awk -v e1="$e1" -v e2="$e2" -v t1="$t1" -v t2="$t2" \
            'BEGIN{printf "%.1f", (e2-e1)/1e6/((t2-t1)/1e9)}')

          if [ -n "$nvidia_smi" ]; then
            gpu=$("$nvidia_smi" --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null \
              | awk '{sum+=$1} END{printf "%.1f", sum}')
            if [ -z "$gpu" ]; then
              gpu="0.0"
            fi
          else
            gpu="0.0"
          fi

          total=$(awk -v c="$cpu" -v g="$gpu" -v b="$baseline" \
            'BEGIN{printf "%.1f", c+g+b}')

          printf "CPU %s W | GPU %s W | Est %s W (baseline %s W)\n" "$cpu" "$gpu" "$total" "$baseline"
        done
      '')

## add some gnome packages
      gnome-keyring
      gnome-disk-utility
      nautilus
      zenity
      gnome-tweaks
      eog
      gvfs
      # dconf-editor
      happy-coder
      kiro-cli
      codex-switcher
  ]);
}
