{ config, lib, pkgs, ... }:

{
    programs.waybar = {
      enable = true;
      systemd = {
        enable = false;
        target = "graphical-session.target";
      };
      style = ''
window#waybar.hidden {
  opacity: 0.2;
}
#window {
  margin-top: 6px;
  padding-left: 10px;
  padding-right: 10px;
  border-radius: 10px;
  transition: none;
  color: transparent;
  background: transparent;
}
* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 12pt;
  min-height: 10px;
  font-weight: bold;
  border: none;
  border-radius: 10px;
  transition-property: background-color;
  transition-duration: 0.5s;
}
@keyframes blink_red {
  to {
    background-color: rgb(242, 143, 173);
    color: rgb(26, 24, 38);
  }
}
.warning, .critical, .urgent {
  animation-name: blink_red;
  animation-duration: 1s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}
window#waybar {
  background-color: transparent;
}
#workspaces {
  padding-left: 0px;
  padding-right: 4px;
}
#workspaces button {
  padding-top: 5px;
  padding-bottom: 5px;
  padding-left: 6px;
  padding-right: 6px;
}
#workspaces button.active {
  background-color: rgb(181, 232, 224);
  color: rgb(26, 24, 38);
}
#workspaces button.urgent {
  color: rgb(26, 24, 38);
}
#workspaces button:hover {
  background-color: rgb(248, 189, 150);
  color: rgb(26, 24, 38);
}
tooltip {
  background: rgb(48, 45, 65);
}
tooltip label {
  color: rgb(217, 224, 238);
}
#mode, #clock, #memory, #temperature,#cpu, #temperature, #backlight, #pulseaudio, 
#network, #battery, #cpu,  #workspaces, #custom-weather, #tray, #custom-acpi-performance {
  padding-left: 10px;
  padding-right: 10px;
  background: #1e1e2a;
}
/* #mode { */
/* 	margin-left: 10px; */
/* 	background-color: rgb(248, 189, 150); */
/*     color: rgb(26, 24, 38); */
/* } */
#memory {
  color: rgb(181, 232, 224);
}
#cpu {
  color: rgb(245, 194, 231);
}
#clock {
  color: rgb(217, 224, 238);
}
/* #idle_inhibitor {
color: rgb(221, 182, 242);
}*/
#temperature {
  color: rgb(150, 205, 251);
}
#backlight {
  color: rgb(248, 189, 150);
}
#pulseaudio {
  color: rgb(245, 224, 220);
}
#network {
  color: #ABE9B3;
}
#network.disconnected {
  color: rgb(255, 255, 255);
}
#tray {
  background-color: rgba(223, 192, 238, 0.1); /* Adjust color and opacity as needed */
  border-radius: 10px; /* Adjust for desired roundness */
  padding-top: 4px;
  padding-bottom: 4px;
  padding-right: 12px;
  padding-left: 12px;
}
      '';
      settings = [{
        "layer" = "top";
        "position" = "top";
        modules-left = [
          "custom/weather"
          "battery"
          "hyprland/workspaces"
          "custom/acpi-performance"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "tray"
          # "privacy"
          # "custom/media"
          "pulseaudio"
          "memory"
          "cpu"
          "network"
        ];
        "hyprland/workspaces" = {
          "format" = "<sub>{icon}</sub> {windows} ";
            "format-window-separator" = " ";
            "window-rewrite-default" = "";
            "window-rewrite" = {
              "firefox" = "";
              "kitty" = "";
              "code" = "󰨞";
              "qq" = "󰻀";
              "foliate" = "";
              "steam" = "󰓓";
              "nautilus" = "";
              "cpu-x" = "";
              "misssion-center" = "󰟌";
              "rofi" = "󱓞";
              "mpv" = "";
              "fcitx5" = "󰌌";
            };
        };
        "backlight"= {
          "tooltip"= false;
          "format"= " {}%";
          "on-scroll-up"= "light -A 5";
          "on-scroll-down"= "light -U 5";
        };
        "battery"= {
          "on-scroll-up" = "swaybg -i $WALLPAPER_DIR/space.jpg  -m fill > /dev/null";
          "on-click-right" = "swaybg -i $(find $WALLPAPER_DIR -type f | shuf -n 1) -m fill > /dev/null";
          "states"= {
            "good"= 95;
            "warning"= 30;
            "critical"= 20;
          };
          "format"= "{icon}  {capacity}%";
          "format-charging"= " {capacity}%";
          "format-plugged"= " {capacity}%";
          "format-alt"= "{time} {icon}";
          "format-icons"= ["" "" "" "" ""];
        };
        "custom/weather" = {
          "format" = "{}° ";
          "tooltip" = true;
          "interval" = 3600;
          "exec" = "wttrbar --location Kyoto";
          "return-type" = "json";
        };
        "custom/acpi-performance" = {
          "format"=" 󰉁 ";
          "on-click" = "sudo fdisk -l";
          "tooltip" = false;
        };
        "custom/media"= {
          "max-length"= 20;
          "format"= "  ";
          "return-type"= "json";
          "on-click"= "playerctl play-pause";
          "spacing" = 5;
        };
        "pulseaudio" = {
          "scroll-step" = 1;
          "format" = "{icon} {volume}%";
          "format-muted" = "󰖁 Muted";
          "format-icons" = {
            "default" = [ "" "" "" ];
          };
          "on-click" = "pamixer -t";
          "tooltip" = false;
        };
        "clock" = {
          "interval" = 1;
          "format" = "{:%I:%M %p}";
          "tooltip" = true;
          "tooltip-format"= "{%A %b %d}";
        };
        "memory" = {
          "interval" = 1;
          "format" = "󰻠 {percentage}%";
          "states" = {
            "warning" = 85;
          };
        };
        "cpu" = {
          "interval" = 1;
          "format" = "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7}";
          "format-icons" = [
            "<span color='#69ff94'>▁</span>"  # green
            "<span color='#2aa9ff'>▂</span>"  # blue
            "<span color='#f8f8f2'>▃</span>"  # white
            "<span color='#f8f8f2'>▄</span>"  # white
            "<span color='#ffffa5'>▅</span>"  # yellow
            "<span color='#ffffa5'>▆</span>"  # yellow
            "<span color='#ff9977'>▇</span>"  # orange
            "<span color='#dd532e'>█</span>"  # red
          ];
        };
        "network" = {
          "format-disconnected" = "󰯡 Disconnected";
          "format-ethernet" = "󰒢 ";
          "format-linked" = "󰖪 {essid} (No IP)";
          "format-wifi" = "󰖩 {essid}";
          "interval" = 1;
          "tooltip" = false;
        };
        "privacy"= {
          "icon-spacing"= 4;
          "icon-size"= 18;
          "transition-duration"= 250;
          "modules"= [
          {
            "type"= "screenshare";
            "tooltip"= true;
            "tooltip-icon-size"= 24;
          }
          {
            "type"= "audio-out";
            "tooltip"= true;
            "tooltip-icon-size"= 24;
          }
          {
            "type"= "audio-in";
            "tooltip"= true;
            "tooltip-icon-size"= 24;
          }
          ];
        };
        "tray" = {
          "icon-size" = 15;
          "spacing" = 10;
        };
      }];
    };
}
