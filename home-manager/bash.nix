{ lib, config, pkgs, ... }: {
    programs.bash.enable = true;

    programs.bash.shellAliases = {
        ls = "exa -lab --icons --git";
        tree = "exa -T -L";
        less = "bat";
        cat = "bat";
        grep = "grep --color=auto";
        du = "dust";
        df = "duf";
        chat = "chatgpt";
        j = "joshuto";
        cbp = "convert-blog-picture.sh";
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
        lsblk = "lsblk -f";
        hm = "home-manager switch --flake .#kud@Lain --extra-experimental-features nix-command --extra-experimental-features flakes";
        nb = "sudo nixos-rebuild switch --flake .#Lain";
    };

    programs.bash.sessionVariables = {
        MAKEFLAGES = "-j20";
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    };
}
