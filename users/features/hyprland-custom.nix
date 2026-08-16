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
    # External script dependencies
    rofi pavucontrol fortune wl-screenrec alsa-utils swww networkmanager_dmenu
    wl-clipboard fd qt6.qtmultimedia qt6.qt5compat qt6.qtwebsockets qt6.qtwebengine
    ripgrep gtk3 cava cliphist tree jq socat pamixer brightnessctl acpi iw bluez
    networkmanager lm_sensors bc pulseaudio ladspaPlugins ladspa-sdk imagemagick
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
      
      # 2. Native workspace navigation (AZERTY)
      bind = SUPER, ampersand, workspace, 1
      bind = SUPER, eacute, workspace, 2
      bind = SUPER, quotedbl, workspace, 3
      bind = SUPER, apostrophe, workspace, 4

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
    '';

    # Leave settings empty to enforce strict ordering in extraConfig
    settings = {};
  };
}
