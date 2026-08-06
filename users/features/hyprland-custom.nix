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

  # Generate Hyprland bind array
  dynamicBinds = lib.mapAttrsToList (name: data: 
    "${convertBinding (builtins.elemAt data 2)}, exec, ${builtins.elemAt data 1}"
  ) allShortcuts;
in
{
  home.packages = with pkgs; [
    wofi
    grim
    slurp
    wl-clipboard
    libnotify
  ];

  # Enable Wayland notification daemon
  services.mako = {
    enable = true;
    defaultTimeout = 4000;
  };
  
  # Abort the build if duplicate shortcut bindings are detected
  assertions = [
    {
      assertion = builtins.length allBindingsList == builtins.length uniqueBindings;
      message = "Conflict detected in shortcuts.list.nix bindings for Hyprland.";
    }
  ];
  
  wayland.windowManager.hyprland = {
    enable = true;
    
    settings = {
      # Startup programs
        exec-once = [
        "mako"
      ];
      
      # Define primary modifier key
      "$mainMod" = "SUPER";

      # Configure window gaps and borders
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Set basic aesthetic parameters
      decoration = {
        rounding = 10;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

     # Configure keyboard layout (AZERTY)
     input = {
       kb_layout = "fr";
     };

      # Define core keyboard shortcuts
      bind = [
        "$mainMod, R, exec, wofi --show drun"
        "$mainMod, X, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, G, fullscreen,"

        # Screenshot utility (select area and copy to clipboard)
        "$mainMod SHIFT, S, exec, grim -g \"$(slurp -d)\" - | wl-copy"
        
        # Window focus management
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Workspace navigation
        "$mainMod, ampersand, workspace, 1"
        "$mainMod, eacute, workspace, 2"
        "$mainMod, quotedbl, workspace, 3"
        "$mainMod, apostrophe, workspace, 4"
         
        # Move active window to a workspace
        "$mainMod SHIFT, ampersand, movetoworkspace, 1"
        "$mainMod SHIFT, eacute, movetoworkspace, 2"
        "$mainMod SHIFT, quotedbl, movetoworkspace, 3"
        "$mainMod SHIFT, apostrophe, movetoworkspace, 4"
      ] ++ dynamicBinds;
      
      # Mouse bindings for window management
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
