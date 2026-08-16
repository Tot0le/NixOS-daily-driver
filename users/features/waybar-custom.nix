{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "network" "battery" "tray" ];
        
        network = {
          format-ethernet = "ETH {ipaddr}";
          format-wifi = "WIFI {essid}";
          format-disconnected = "Offline";
        };
      };
    };
    
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: sans-serif;
        font-size: 14px;
      }
      window#waybar {
        background: rgba(26, 26, 26, 0.9);
        color: #ffffff;
      }
      #workspaces button {
        padding: 0 10px;
        color: #aaaaaa;
      }
      #workspaces button.active {
        background: #33ccff;
        color: #000000;
        border-radius: 5px;
      }
      #clock, #battery, #network, #window {
        padding: 0 10px;
      }
    '';
  };
}
