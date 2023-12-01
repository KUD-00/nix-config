{ config, pkgs, ... }:

{
  home = {
    sessionVariables = rec {
      BROWSER = "firefox";
      TERMINAL = "kitty";
      __GL_VRR_ALLOWED="1";
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      CLUTTER_BACKEND = "wayland";
      WLR_RENDERER = "vulkan";

      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";

      MAKEFLAGES = "-j20";
      HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      EDITOR = "nvim";
      NIX_BUILD_CORES = "20";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONEREPARENTING = "1";
      GDK_BACKEND = "wayland";

      WALLPAPER_DIR = "$HOME/Documents/wallpapers";
      DEVELOPER_DIR = "$HOME/Developer";
      BLOG_DIR = "${DEVELOPER_DIR}/blog";

      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_BROKEN = "1";
    };
  };
}
