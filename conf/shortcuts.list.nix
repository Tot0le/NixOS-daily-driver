# /etc/nixos/conf/shortcuts.list.nix

{
  # Schema: name = [ "Display Name" "Command" "Binding" ];

  # Standard applications for all user profiles
  commonApps = {
    browser  = [ "Browser" "firefox" "<Super>f" ];
    explorer = [ "Explorer" "nautilus" "<Super>e" ];
    lock     = [ "Lock Screen" "~/.config/hypr/scripts/lock.sh" "<Super>l" ];
    reload   = [ "Reload Shell" "~/.config/hypr/scripts/reload.sh" "<Super><Shift>r" ];

    # Hardware media controls
    volUp    = [ "Volume Up" "pamixer -i 5" ", XF86AudioRaiseVolume" ];
    volDown  = [ "Volume Down" "pamixer -d 5" ", XF86AudioLowerVolume" ];
    mute     = [ "Mute" "pamixer -t" ", XF86AudioMute" ];
    play     = [ "Play/Pause" "playerctl play-pause" ", XF86AudioPlay" ];
    next     = [ "Next Track" "playerctl next" ", XF86AudioNext" ];
    prev     = [ "Previous Track" "playerctl previous" ", XF86AudioPrev" ];
    stop     = [ "Stop Track" "playerctl stop" ", XF86AudioStop" ];
  };

  # Only meaningful inside a Hyprland/Quickshell session — never pushed to GNOME
  quickshellApps = {
    launcher  = [ "App Launcher" "~/.config/hypr/scripts/qs_manager.sh toggle applauncher" "<Super>r" ];
    monitors  = [ "Toggle Monitors" "~/.config/hypr/scripts/qs_manager.sh toggle monitors" "<Super>m" ];
    settings  = [ "Toggle Settings" "~/.config/hypr/scripts/qs_manager.sh toggle settings" "<Super><Shift>s" ];
    battery   = [ "Toggle Battery" "~/.config/hypr/scripts/qs_manager.sh toggle battery" "<Super>b" ];
    focustime = [ "Toggle Focus Time" "~/.config/hypr/scripts/qs_manager.sh toggle focustime" "<Super><Shift>t" ];
    guide     = [ "Toggle Guide" "~/.config/hypr/scripts/qs_manager.sh toggle guide" "<Super>h" ];

    togglePerf      = [ "Toggle Performance" "~/.config/hypr/scripts/qs_manager.sh toggle dashboard 1" "<Super>a" ];
    toggleDraw      = [ "Toggle Draw" "~/.config/hypr/scripts/qs_manager.sh toggle dashboard 0" "<Super>d" ];
    toggleTimer     = [ "Toggle Timer" "~/.config/hypr/scripts/qs_manager.sh toggle dashboard 2" "<Super>u" ];
    toggleCalendar  = [ "Toggle Calendar" "~/.config/hypr/scripts/qs_manager.sh toggle calendar" "<Super>p" ];
    toggleClipboard = [ "Toggle Clipboard" "~/.config/hypr/scripts/qs_manager.sh toggle clipboard" "<Super>v" ];
    toggleNetwork   = [ "Toggle Network" "~/.config/hypr/scripts/qs_manager.sh toggle network" "<Super>n" ];
    toggleVolume    = [ "Toggle Volume" "~/.config/hypr/scripts/qs_manager.sh toggle volume" "<Super>y" ];
    toggleWallpaper = [ "Toggle Wallpaper" "~/.config/hypr/scripts/qs_manager.sh toggle wallpaper" "<Super>w" ];
    toggleMusic     = [ "Toggle Music Player" "~/.config/hypr/scripts/qs_manager.sh toggle music" "<Super>o" ];
    toggleMovies    = [ "Toggle Movies" "~/.config/hypr/scripts/qs_manager.sh toggle movies" "<Super>g" ];
  };

  # Tools for advanced terminal environments (Kitty, etc.)
  terminalTools = {
    terminal = [ "Terminal" "kitty" "<Super>c" ];
    kittyOpaque = [ "Terminal Opaque" "set_opacity 1.0" "<Ctrl><Shift>o" ];
    kittyTransp = [ "Terminal Transparent" "set_opacity 0.5" "<Ctrl><Shift>p" ];
    togglePrompt = [ "Toggle Prompt" "toggle_prompt" "<Super>t" ];
  };

  # Administrative tools restricted to elevated profiles
  adminApps = {
  };

  # Optional graphic utilities
  graphicTools = {
    picker   = [ "Picker" "pick_color.sh" "<Super>ugrave" ];
  };

  # Hardware control mapped to function keys
  fans = {
    fanMinus2   = [ "Fan -2%" "fan_control.sh minus 2" "<Super>F1" ];
    fanPlus2    = [ "Fan +2%" "fan_control.sh plus 2" "<Super>F2" ];
    fanMinus10  = [ "Fan -10%" "fan_control.sh minus 10" "<Super>F3" ];
    fanPlus10   = [ "Fan +10%" "fan_control.sh plus 10" "<Super>F4" ];
    fanSet50    = [ "Fan 50%" "fan_control.sh set 50" "<Super>F5" ];
    fanSet80    = [ "Fan 80%" "fan_control.sh set 80" "<Super>F6" ];
    fanSet100   = [ "Fan 100%" "fan_control.sh set 100" "<Super>F7" ];
  };
 
  # System-wide overrides for existing GNOME shortcuts
  systemOverrides = {
    "/org/gnome/settings-daemon/plugins/media-keys/help" = "['']"; # Release F1 key mapping
    "/org/gnome/desktop/wm/keybindings/switch-group" = "['<Alt>Above_Tab']"; # Override window group switching
  };
}
