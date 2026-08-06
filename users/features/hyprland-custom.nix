{ config, pkgs, ... }:

{
  home.packages = [ pkgs.wofi ];
  
  wayland.windowManager.hyprland = {
    enable = true;
    
    settings = {
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
        "$mainMod, Q, exec, kitty"
        "$mainMod, R, exec, wofi --show drun"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, G, fullscreen,"
        
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
      ];
      
      # Mouse bindings for window management
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
