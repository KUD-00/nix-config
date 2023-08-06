{ lib, config, pkgs, ... }: {
        programs.bash = {
                enable = true;

                shellAliases = {
                        ls = "exa -lab --icons --git";
                        tree = "exa -I .git -T -L ";
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
                        hm = "home-manager switch --flake .#kud@Lain";
                        nb = "sudo nixos-rebuild switch --flake .#Lain";
                        update = "nix flake update; nb; hm";
                        ps = "procs";
                        cbp = "~/Developer/scripts/compress-blog-image.sh";
                        cache = "sudo nix-collect-garbage; sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d; sudo nix store gc --debug";
                        suspend = "sudo systemctl suspend";
                        nix-history = "sudo nix profile history --profile /nix/var/nix/profiles/system";
                };

                initExtra = ''
                         function set_wayland_env {
                            cd ~
                            # 解决QT程序缩放问题
                            export QT_AUTO_SCREEN_SCALE_FACTOR=1
                            # QT使用wayland和gtk
                            export QT_QPA_PLATFORM="wayland;xcb"
                            export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
                            # 使用qt5ct软件配置QT程序外观
                            export QT_QPA_PLATFORMTHEME=qt5ct

                            # 一些游戏使用wayland
                            export SDL_VIDEODRIVER=wayland
                            # 解决java程序启动黑屏错误
                            export _JAVA_AWT_WM_NONEREPARENTING=1
                            # GTK后端为 wayland和x11,优先wayland
                            export GDK_BACKEND="wayland,x11"
                         }

                         function hyprland {
                           set_wayland_env

                           export XDG_SESSION_TYPE=wayland
                           export XDG_SESSION_DESKTOP=Hyprland
                           export XDG_CURRENT_DESKTOP=Hyprland

                           exec Hyprland
                         }

                         function nd () {
                           mkdir -p -- "$1" &&
                           cd -P -- "$1"
                         }
                   '';

                sessionVariables = {
                        MAKEFLAGES = "-j20";
                        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
                        EDITOR = "nvim";
                        NIX_BUILD_CORES = "20";
                };
        };
}
