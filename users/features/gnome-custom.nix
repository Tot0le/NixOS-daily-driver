# /etc/nixos/users/features/gnome-custom.nix
{ config, pkgs, lib, ... }:

let
  # Default fallback wallpaper
  defaultWallpaper = "${../../conf/theme/wallpaper.jpg}";
in
{
  # Define per-user customization options
  options.my.gnome = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = defaultWallpaper;
      description = "Path to the user wallpaper file.";
    };
    desktopIcons = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable or disable desktop icons (DING).";
    };
    taskbar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable a persistent or intellihide taskbar (Dash-to-Dock extension).";
    };
  };

  config = {
    # Install extensions based on user-defined options
    home.packages = with pkgs.gnomeExtensions; [
      dash-to-dock
      blur-my-shell
      just-perfection
      appindicator
    ] ++ lib.optionals config.my.gnome.desktopIcons [
      desktop-icons-ng-ding
    ] ++ lib.optionals config.my.gnome.taskbar [
      dash-to-dock
    ];

    # Manage global desktop appearance via GTK
    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Mocha-Compact-Blue-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "blue" ];
          size = "compact";
          variant = "mocha";
        };
      };
      iconTheme = {
        name = "Tela-circle-dark";
        package = pkgs.tela-circle-icon-theme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    # Force stubborn applications to use the dark theme
    home.sessionVariables.GTK_THEME = "Catppuccin-Mocha-Compact-Blue-Dark";

    # Persist theme and extension settings in the dconf database
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
      "org/gnome/desktop/wm/preferences" = {
        theme = "Catppuccin-Mocha-Compact-Blue-Dark";
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${config.my.gnome.wallpaper}";
        picture-uri-dark = "file://${config.my.gnome.wallpaper}";
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://${config.my.gnome.wallpaper}";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "blur-my-shell@aunetx"
          "just-perfection-desktop@just-perfection"
          "appindicatorsupport@rgcjonas.gmail.com"
        ] ++ lib.optionals config.my.gnome.desktopIcons [
          "ding@rastersoft.com"
        ] ++ lib.optionals config.my.gnome.taskbar [
          "dash-to-dock@micxgx.gmail.com"
        ];
        disabled-extensions = lib.optionals (!config.my.gnome.taskbar) [
          "dash-to-dock@micxgx.gmail.com"
        ];
      };
      # Conditionally configure the dock only if the extension is enabled
      "org/gnome/shell/extensions/dash-to-dock" = lib.mkIf config.my.gnome.taskbar {
        intellihide = true;
      };
    };

    # Auto-generate a comprehensive beginner tutorial in the Pictures folder
    home.file."Pictures/README-wallpaper.txt".text = ''
      ================================================
      🎨 TUTORIAL: HOW TO CHANGE YOUR WALLPAPER
      ================================================
    
      1. OPEN THE TERMINAL (OR CONSOLE):
         - Press Super + C (Your custom keyboard shortcut).
         - OR press the 'Windows' key (Super), type 'Console' or 'Terminal', and press Enter.
    
      2. OPEN YOUR PERSONAL CONFIGURATION FILE:
         - In the console, type the following command and press Enter:
           micro ~/.config/home-manager/home.nix
    
      3. MODIFY THE WALLPAPER PATH:
         - Use the arrow keys to find the line: my.gnome.wallpaper
         - Change the path inside the quotes to your new image.
         - NOTE: The path "/home/${config.home.username}/Pictures" is exactly 
           the 'Pictures' folder you see in your file explorer.
         - Example: my.gnome.wallpaper = "/home/${config.home.username}/Pictures/my_new_photo.jpg";
         - To Save: Press Ctrl + S
         - To Quit: Press Ctrl + Q
    
      4. APPLY YOUR CHANGES:
         - In the console, type this command and press Enter:
           home-manager switch
    
      ⚠️ IMPORTANT: THE GNOME CACHE TRAP ⚠️
      If you replace your image file but keep the SAME name (e.g., default_wallpaper.jpg),
      GNOME will not see the change immediately due to memory caching.
      -> SOLUTION: Log out of your session and log back in, or simply use a different filename!
    '';

    # Prevent basic wallpaper: Copy default wallpaper if the user's target path doesn't exist yet
    home.activation.initWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET_WALLPAPER="${config.my.gnome.wallpaper}"
      TARGET_DIR=$(dirname "$TARGET_WALLPAPER")
      
      if [ ! -f "$TARGET_WALLPAPER" ]
      then
        $DRY_RUN_CMD mkdir -p "$TARGET_DIR"
        $DRY_RUN_CMD cp ${defaultWallpaper} "$TARGET_WALLPAPER"
        $DRY_RUN_CMD chmod 644 "$TARGET_WALLPAPER"
      fi
    '';
  };
 }
