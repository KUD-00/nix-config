{ lib, config, pkgs, ... }: 

{
  programs.bash = {
    enable = true;

    shellAliases = {
      ls = "eza --long --icons --hyperlink --classify --all --bytes --header --modified --mounts --git";
      tree = "eza -I .git -T -L ";
      less = "bat";
      cat = "bat";
      grep = "grep -i --color=auto";
      du = "dust";
      df = "duf";
      chat = "chatgpt";
      j = "joshuto";
      routine = "routine.sh";
      rocm = "sudo docker run \
              -it \
              --network=host \
              --device=/dev/kfd \
              --device=/dev/dri \
              --ipc=host \
              --shm-size 16G \
              --group-add video \
              --cap-add=SYS_PTRACE \
              --security-opt seccomp=unconfined \
              -v $HOME/dockerx:/dockerx";
      gaa = "git add -A";
      gba = "git branch -vv --all";
      gcm = "git commit -m ";
      gpush = "git push";
      gpull = "git pull";
      gstat = "git status";
      gs = "git status";
      lsblk = "lsblk -f";
      hm = "home-manager switch --flake .#$USER@$HOSTNAME";
      nb = "sudo nixos-rebuild switch --flake .#$HOSTNAME";
      update = "nix flake update; nb; hm";
      ps = "procs";
      cbp = "~/Developer/scripts/compress-blog-image.sh";
      cache = "sudo nix-collect-garbage; sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d; sudo nix store gc --debug";
      suspend = "sudo systemctl suspend";
      nix-history = "sudo nix profile history --profile /nix/var/nix/profiles/system";
      chromium = "chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime";
    };

    initExtra = ''
    function nd () {
      mkdir -p -- "$1" &&
        cd -P -- "$1"
    }
    function cd() {
      builtin cd "$@" && {
        if [ -f "shell.nix" ]; then
          echo "Entering nix-shell due to presence of shell.nix"
          nix-shell
        fi
      }
    }
    '';
  };
}
