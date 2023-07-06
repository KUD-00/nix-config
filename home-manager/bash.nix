{ lib, config, pkgs, ... }: {
    programs.bash.enable = true;

    programs.bash.shellAliases = {
        ls = "exa -lab --icons --git";
        tree = "exa -T -L";
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
        gs = "git status";
        lsblk = "lsblk -f";
        hm = "home-manager switch --flake .#kud@Lain";
        nb = "sudo nixos-rebuild switch --flake .#Lain";
        update = "nix flake update; nb; hm";
        ps = "procs";
        cbp = "~/Developer/scripts/compress-blog-image.sh";
        cache = "sudo nix-collect-garbage; sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d; sudo nix store gc --debug";
        suspend = "sudo systemctl suspend";
        nix-history = "sudo nix profile history --profile /nix/var/nix/profiles/system";
    };

    programs.bash.sessionVariables = {
        MAKEFLAGES = "-j20";
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    };

    # programs.bash.initExtra = "atuin init bash";
}
