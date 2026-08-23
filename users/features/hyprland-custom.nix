{ config, pkgs, lib, ... }:

let
  # Import the centralized shortcut catalog
  shortcutCatalog = import ../../conf/shortcuts.list.nix;
  allShortcuts = shortcutCatalog.commonApps // shortcutCatalog.terminalTools // shortcutCatalog.graphicTools // shortcutCatalog.fans;
  
  # Convert GNOME binding syntax to Hyprland syntax
  convertBinding = gnomeBind:
    let
      s0 = builtins.replaceStrings ["<Super><Shift>"] ["SUPER SHIFT, "] gnomeBind;
      s1 = builtins.replaceStrings ["<Super>"] ["SUPER, "] s0;
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
    rofi pavucontrol fortune wl-screenrec alsa-utils awww networkmanager_dmenu
    wl-clipboard fd qt6.qtmultimedia qt6.qt5compat qt6.qtwebsockets qt6.qtwebengine
    ripgrep gtk3 cava cliphist tree jq socat pamixer brightnessctl acpi iw bluez
    networkmanager lm_sensors bc pulseaudio ladspaPlugins ladspa-sdk imagemagick

    # Performance & Media tools
    inotify-tools
    playerctl
    
    # Fonts for Quickshell UI
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono

    # Hyprland wallpaper dependencies
    imagemagick
    ffmpeg
    awww
    mpvpaper
    matugen

    # Screenshot system dependencies
    gpu-screen-recorder
    grim
    satty
    zbar
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
      bind = SUPER SHIFT, M, exit
      
      # Workspace switching by physical keycode (layout-independent — works on AZERTY, QWERTY, etc.)
      bind = SUPER, code:10, exec, bash ~/.config/hypr/scripts/qs_manager.sh 1
      bind = SUPER, code:11, exec, bash ~/.config/hypr/scripts/qs_manager.sh 2
      bind = SUPER, code:12, exec, bash ~/.config/hypr/scripts/qs_manager.sh 3
      bind = SUPER, code:13, exec, bash ~/.config/hypr/scripts/qs_manager.sh 4
      bind = SUPER, code:14, exec, bash ~/.config/hypr/scripts/qs_manager.sh 5
      bind = SUPER, code:15, exec, bash ~/.config/hypr/scripts/qs_manager.sh 6
      bind = SUPER, code:16, exec, bash ~/.config/hypr/scripts/qs_manager.sh 7
      bind = SUPER, code:17, exec, bash ~/.config/hypr/scripts/qs_manager.sh 8
      bind = SUPER, code:18, exec, bash ~/.config/hypr/scripts/qs_manager.sh 9
      bind = SUPER, code:19, exec, bash ~/.config/hypr/scripts/qs_manager.sh 10

      bind = SUPER SHIFT, code:10, exec, bash ~/.config/hypr/scripts/qs_manager.sh 1 move
      bind = SUPER SHIFT, code:11, exec, bash ~/.config/hypr/scripts/qs_manager.sh 2 move
      bind = SUPER SHIFT, code:12, exec, bash ~/.config/hypr/scripts/qs_manager.sh 3 move
      bind = SUPER SHIFT, code:13, exec, bash ~/.config/hypr/scripts/qs_manager.sh 4 move
      bind = SUPER SHIFT, code:14, exec, bash ~/.config/hypr/scripts/qs_manager.sh 5 move
      bind = SUPER SHIFT, code:15, exec, bash ~/.config/hypr/scripts/qs_manager.sh 6 move
      bind = SUPER SHIFT, code:16, exec, bash ~/.config/hypr/scripts/qs_manager.sh 7 move
      bind = SUPER SHIFT, code:17, exec, bash ~/.config/hypr/scripts/qs_manager.sh 8 move
      bind = SUPER SHIFT, code:18, exec, bash ~/.config/hypr/scripts/qs_manager.sh 9 move
      bind = SUPER SHIFT, code:19, exec, bash ~/.config/hypr/scripts/qs_manager.sh 10 move

      # 2. Dynamic injected bindings
      ${dynamicBindsText}

      # 3. External modular configuration
      source = ~/.config/hypr/colors.conf
      source = ~/.config/hypr/config/monitors.conf
      source = ~/.config/hypr/config/env.conf
      source = ~/.config/hypr/config/autostart.conf
      source = ~/.config/hypr/config/variables.conf
      source = ~/.config/hypr/config/settings.conf
      source = ~/.config/hypr/config/rules.conf
      source = ~/.config/hypr/config/keybindings.conf

      # User-specific local overrides
      source = ~/.config/hypr/local.conf
    '';

    # Leave settings empty to enforce strict ordering in extraConfig
    settings = {};
  };
}
