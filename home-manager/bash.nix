{ lib, config, pkgs, ... }: 

{
  programs.bash = {
    enable = true;
#TODO: add a alias for atool or archive extraction auto-detect file extension
    shellAliases = {
      ls = "eza --long --icons --hyperlink --classify --all --bytes --header --modified --mounts --git";
      tree = "eza -I .git -T -L ";
      less = "bat";
      cat = "bat";
      grep = "grep -i --color=auto";
      du = "dust";
      df = "duf";
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
      gs = "git status";
      lsblk = "lsblk -f";
      hm = "home-manager switch --flake .#$USER@$HOSTNAME --show-trace --option eval-cache false";
      nb = "sudo nixos-rebuild switch --flake .#$HOSTNAME";
      update = "nix flake update; nb; hm; flatpak update";
      ps = "procs";
      cache = "sudo nix-collect-garbage; sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d; sudo nix store gc --debug";
      suspend = "sudo systemctl suspend";
      nix-history = "sudo nix profile history --profile /nix/var/nix/profiles/system";
      foliate4 = "flatpak run com.github.johnfactotum.Foliate";
      f = "yazi";
      current-all-packages = "nix-store -q --requisites $CURRENT_NIXOS_SYSTEM";
      where-nix = "current-all-packages | grep -i";
      journalctl = "journalctl -e";
      drv-difference = "nix profile diff-closures --profile /nix/var/nix/profiles/system | less";
      timesync = "sudo systemctl restart systemd-timesyncd.service";
      blog = "builtin cd $BLOG_DIR; pnpm dev";
    };

# any better ideas?
    initExtra = ''
    export CURRENT_NIXOS_SYSTEM=$(readlink -f /nix/var/nix/profiles/system)

    function who-depends-on () {
      nix-store --query --referrers $(where-nix $1)
    }

    function nd () {
      mkdir -p -- "$1" &&
        cd -P -- "$1"
    }

    function cd() {
      builtin cd "$@" && {
        if [ -d ".git" ]; then
          echo "Git repository detected. Fetching latest changes..."
          git fetch --all
          echo "!! remember to git pull !!"
        fi
        if [ -f "shell.nix" ]; then
          echo "Entering nix-shell due to presence of shell.nix"
          nix-shell
        fi
      }
    }

    function cbp() {
      convert $WALLPAPER_DIR/$1 -quality 40% $BLOG_DIR/public/images/blog/$2.jpg
    }
    '';
  };
}
