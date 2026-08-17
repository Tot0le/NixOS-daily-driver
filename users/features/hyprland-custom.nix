{ config, pkgs, lib, ... }:

let
  # Import the centralized shortcut catalog
  shortcutCatalog = import ../../conf/shortcuts.list.nix;
  allShortcuts = shortcutCatalog.commonApps // shortcutCatalog.terminalTools // shortcutCatalog.graphicTools // shortcutCatalog.fans;
  
  # Convert GNOME binding syntax to Hyprland syntax
  convertBinding = gnomeBind:
    let
      s1 = builtins.replaceStrings ["<Super>"] ["SUPER, "] gnomeBind;
      s2 = builtins.replaceStrings ["<Ctrl><Shift>"] ["CTRL SHIFT, "] s1;
      s3 = builtins.replaceStrings ["<Ctrl>"] ["CTRL, "] s2;
      s4 = builtins.replaceStrings ["<Shift>"] ["SHIFT, "] s3;
      s5 = builtins.replaceStrings ["<Alt>"] ["ALT, "] s4;
    in s5;

  # Extract bindings to detect conflicts
  allBindingsList = lib.mapAttrsToList (name: data: convertBinding (builtins.elemAt data 2)) allShortcuts;
  uniqueBindings = lib.unique allBindingsList;

  # Generate Hyprland bind string block
  dynamicBindsText = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (name: data: 
      "bind = ${convertBinding (builtins.elemAt data 2)}, exec, ${builtins.elemAt data 1}"
    ) allShortcuts
  );
in
{
  home.packages = with pkgs; [
    wofi
    hyprshot
    quickshell
    hypridle
    # External script dependencies
    rofi pavucontrol fortune wl-screenrec alsa-utils swww networkmanager_dmenu
    wl-clipboard fd qt6.qtmultimedia qt6.qt5compat qt6.qtwebsockets qt6.qtwebengine
    ripgrep gtk3 cava cliphist tree jq socat pamixer brightnessctl acpi iw bluez
    networkmanager lm_sensors bc pulseaudio ladspaPlugins ladspa-sdk imagemagick

    # Performance & Media tools
    inotify-tools
    playerctl
    
    # Fonts for Quickshell UI
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
  ];

  # Abort the build if duplicate shortcut bindings are detected
  assertions = [
    {
      assertion = builtins.length allBindingsList == builtins.length uniqueBindings;
      message = "Conflict detected in shortcuts.list.nix bindings for Hyprland.";
    }
  ];

  # Link only subdirectories to allow Nix to safely generate the master hyprland.conf
  xdg.configFile."hypr/config".source = ../../conf/hypr/config;
  xdg.configFile."hypr/scripts".source = ../../conf/hypr/scripts;
  xdg.configFile."hypr/colors.conf".source = ../../conf/hypr/colors.conf;

  wayland.windowManager.hyprland = {
    enable = true;
    
    # Inject bindings BEFORE external sources to prevent parser lockouts
    extraConfig = ''
      # 1. Failsafe core bindings
      bind = SUPER, Return, exec, kitty
      bind = SUPER, X, killactive
      bind = SUPER, M, exit

      # Screenshot utility
      bind = , Print, exec, hyprshot -m region --clipboard-only
      bind = SHIFT, Print, exec, hyprshot -m window --clipboard-only
      bind = CTRL, Print, exec, hyprshot -m output --clipboard-only
      
      # 2. Window management and workspace navigation (Keycodes)
      # Switch workspaces (SUPER + 1,2,3,4)
      bind = SUPER, code:10, workspace, 1
      bind = SUPER, code:11, workspace, 2
      bind = SUPER, code:12, workspace, 3
      bind = SUPER, code:13, workspace, 4

      # Move active window to workspace (SUPER + SHIFT + 1,2,3,4)
      bind = SUPER SHIFT, code:10, movetoworkspace, 1
      bind = SUPER SHIFT, code:11, movetoworkspace, 2
      bind = SUPER SHIFT, code:12, movetoworkspace, 3
      bind = SUPER SHIFT, code:13, movetoworkspace, 4

      # Move active window within current workspace (SUPER + SHIFT + Arrows)
      bind = SUPER SHIFT, left, movewindow, l
      bind = SUPER SHIFT, right, movewindow, r
      bind = SUPER SHIFT, up, movewindow, u
      bind = SUPER SHIFT, down, movewindow, d

      # Move/Resize windows with mouse
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # 3. Dynamic injected bindings
      ${dynamicBindsText}

      # 4. External modular configuration
      source = ~/.config/hypr/colors.conf
      source = ~/.config/hypr/config/monitors.conf
      source = ~/.config/hypr/config/env.conf
      source = ~/.config/hypr/config/autostart.conf
      source = ~/.config/hypr/config/variables.conf
      source = ~/.config/hypr/config/settings.conf
      source = ~/.config/hypr/config/rules.conf

      # User-specific local overrides
      source = ~/.config/hypr/local.conf
    '';

    # Leave settings empty to enforce strict ordering in extraConfig
    settings = {};
  };
}
