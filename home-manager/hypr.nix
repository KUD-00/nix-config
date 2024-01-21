{ config, lib, pkgs, hostname, ... }:

let
  MikanSpecificConfig = ''
monitor=,preferred,auto,2

bind=SUPER,B,exec,wtype "\\"
bind=SUPER,U,exec,wtype "_"
bind=SUPER,V,exec,wtype "|"
bind=,code:49,exec,wtype -k Escape

bind=,code:121,exec,pamixer -t
bind=,code:122,exec,pamixer -d 5
bind=,code:123,exec,pamixer -i 5

bind=,code:232,exec,brightnessctl set 10%-
bind=,code:233,exec,brightnessctl set 10%+

bind=$mainMod,H,exec,wtype -P left -p left
bind=$mainMod,J,exec,wtype -P down -p down
bind=$mainMod,K,exec,wtype -P up -p up
bind=$mainMod,L,exec,wtype -P right -p right
  '';

  LainSpecificConfig = ''
monitor=,preferred,auto,auto
'';

  specificConfig = if hostname == "Mikan" then MikanSpecificConfig
                   else if hostname == "Lain" then LainSpecificConfig
                   else "";

in 
{
#test later systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
#     autoLogin = {
#       enable = lib.mkDefault true;
#       shell = lib.mkDefault "bash";
#     };
    extraConfig = ''
env = XCURSOR_SIZE,24

input {
  kb_layout = jp
  kb_variant =
  kb_model =
  kb_options =
  kb_rules =
  follow_mouse = 1
  touchpad {
    natural_scroll = true
  }
  sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

xwayland {
  force_zero_scaling = true
}

general {
  gaps_in = 5
  gaps_out = 20
  border_size = 2
  col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
  col.inactive_border = rgba(595959aa)
  layout = dwindle
}

decoration {
  rounding = 0
  active_opacity = 0.95
  inactive_opacity = 0.9

  drop_shadow = true
  shadow_range = 4
  shadow_render_power = 3
  col.shadow = rgba(1a1a1aee)
}

animations {
  enabled = true
  bezier = myBezier, 0.05, 0.9, 0.1, 1.05

  animation = windows, 1, 7, myBezier
  animation = windowsOut, 1, 7, default, popin 80%
  animation = border, 1, 10, default
  animation = borderangle, 1, 8, default
  animation = fade, 1, 7, default
  animation = workspaces, 1, 6, default
}

dwindle {
  pseudotile = true # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
  preserve_split = true # you probably want this
}

master {
  new_is_master = true
}

gestures {
  workspace_swipe = false
}

device:epic-mouse-v1 {
  sensitivity = -0.5
}

$mainMod = ALT
$altMod=SUPER_ALT

$menu=rofi -show drun

$screen_file=$HOME/Documents/ScreenShots/screen_shot_$(date + "%Y-%m-%d_%H-%M-%S").png

exec-once=dunst
exec-once=swaybg -i $(find $WALLPAPER_DIR -type f | shuf -n 1) -m fill
exec-once=waybar
exec-once=fcitx5 --replace -d
source=$HOME/.config/hypr/colors
windowrulev2=float, class:^(*polkit*)$

exec-once=wl-paste --type text --watch cliphist store
exec-once=wl-paste --type image --watch cliphist store

bind=SUPER_SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy 

bind=, Print,      exec, grim $screen_file
bind=SUPER, S, exec, grim -g "$(slurp)" - | wl-copy -t image/png

bind = $mainMod, Q, exec, kitty
bind = $mainMod, P, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, nautilus
bind = $mainMod, V, togglefloating
bind = $mainMod, SPACE, exec, $menu
bind = $mainMod, F, fullscreen,

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
'' + specificConfig;
};

  home.file.".config/hypr/colors".text = ''
$background = rgba(1d192bee)
$foreground = rgba(c3dde7ee)

$color0 = rgba(1d192bee)
$color1 = rgba(465EA7ee)
$color2 = rgba(5A89B6ee)
$color3 = rgba(6296CAee)
$color4 = rgba(73B3D4ee)
$color5 = rgba(7BC7DDee)
$color6 = rgba(9CB4E3ee)
$color7 = rgba(c3dde7ee)
$color8 = rgba(889aa1ee)
$color9 = rgba(465EA7ee)
$color10 = rgba(5A89B6ee)
$color11 = rgba(6296CAee)
$color12 = rgba(73B3D4ee)
$color13 = rgba(7BC7DDee)
$color14 = rgba(9CB4E3ee)
$color15 = rgba(c3dde7ee)
'';
}
