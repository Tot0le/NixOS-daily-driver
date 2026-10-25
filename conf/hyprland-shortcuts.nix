# Serpantinum shortcuts, as of v2.3.0 (generated from its keybinds.lua).
#
# Every upstream shortcut is listed below. Commented out = unchanged.
# To move one: uncomment it and put the new key on the right-hand side.
# To disable one: uncomment it and set it to null.
# Workspaces are not listed: see hyprland-custom.nix (key codes, for AZERTY).
# Your own application shortcuts live in shortcuts.list.nix.
{
  # "SUPER + mouse:272" = "SUPER + mouse:272";  # hl.dsp.window.drag(), { mouse = true }
  # "SUPER + mouse:273" = "SUPER + mouse:273";  # hl.dsp.window.resize(), { mouse = true }
  # "SUPER + SHIFT + Left" = "SUPER + SHIFT + Left";  # hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true }
  # "SUPER + SHIFT + Right" = "SUPER + SHIFT + Right";  # hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true }
  # "SUPER + SHIFT + Up" = "SUPER + SHIFT + Up";  # hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true }
  # "SUPER + SHIFT + Down" = "SUPER + SHIFT + Down";  # hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true }
  # "SUPER + CTRL + Left" = "SUPER + CTRL + Left";  # hl.dsp.window.move({ direction = "l" })
  # "SUPER + CTRL + Right" = "SUPER + CTRL + Right";  # hl.dsp.window.move({ direction = "r" })
  # "SUPER + CTRL + Up" = "SUPER + CTRL + Up";  # hl.dsp.window.move({ direction = "u" })
  # "SUPER + CTRL + Down" = "SUPER + CTRL + Down";  # hl.dsp.window.move({ direction = "d" })
  # "SUPER + Left" = "SUPER + Left";  # hl.dsp.focus({ direction = "left" })
  # "SUPER + Right" = "SUPER + Right";  # hl.dsp.focus({ direction = "right" })
  # "SUPER + Up" = "SUPER + Up";  # hl.dsp.focus({ direction = "up" })
  # "SUPER + Down" = "SUPER + Down";  # hl.dsp.focus({ direction = "down" })
  "SUPER + Q" = "SUPER + X";  # hl.dsp.window.close()
  # "SUPER + ALT + F" = "SUPER + ALT + F";  # hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })
  # "SUPER + SHIFT + F" = "SUPER + SHIFT + F";  # hl.dsp.window.float({ action = "toggle" })
  # "XF86MonBrightnessDown" = "XF86MonBrightnessDown";  # hl.dsp.exec_cmd("serpantinum brightness lower"), { locked = true }
  # "XF86MonBrightnessUp" = "XF86MonBrightnessUp";  # hl.dsp.exec_cmd("serpantinum brightness raise"), { locked = true }
  # "Print" = "Print";  # hl.dsp.exec_cmd("serpantinum screenshot"), { locked = true }
  # "SHIFT + Print" = "SHIFT + Print";  # hl.dsp.exec_cmd("serpantinum screenshot --edit"), { locked = true }
  # "SUPER + Print" = "SUPER + Print";  # hl.dsp.exec_cmd("serpantinum screenshot --full"), { locked = true }
  # "SUPER + SHIFT + Print" = "SUPER + SHIFT + Print";  # hl.dsp.exec_cmd("serpantinum screenshot --full --edit"), { locked = true }
  # "XF86PowerOff" = "XF86PowerOff";  # hl.dsp.exec_cmd("serpantinum lock"), { locked = true }
  # "SUPER + L" = "SUPER + L";  # hl.dsp.exec_cmd("serpantinum lock"), { repeating = true, locked = true }
  # "SUPER + SPACE" = "SUPER + SPACE";  # hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }
  # "XF86AudioPause" = "XF86AudioPause";  # hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }
  # "XF86AudioPlay" = "XF86AudioPlay";  # hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }
  # "XF86AudioPrev" = "XF86AudioPrev";  # hl.dsp.exec_cmd("playerctl previous"), { locked = true }
  # "XF86AudioNext" = "XF86AudioNext";  # hl.dsp.exec_cmd("playerctl next"), { locked = true }
  # "XF86AudioMicMute" = "XF86AudioMicMute";  # hl.dsp.exec_cmd("serpantinum volume mic-toggle"), { locked = true }
  # "XF86AudioMute" = "XF86AudioMute";  # hl.dsp.exec_cmd("serpantinum volume mute-toggle"), { locked = true }
  # "XF86AudioLowerVolume" = "XF86AudioLowerVolume";  # hl.dsp.exec_cmd("serpantinum volume lower"), { repeating = true, locked = true }
  # "XF86AudioRaiseVolume" = "XF86AudioRaiseVolume";  # hl.dsp.exec_cmd("serpantinum volume raise"), { repeating = true, locked = true }
  # "SUPER + F" = "SUPER + F";  # hl.dsp.exec_cmd("firefox")
  # "SUPER + E" = "SUPER + E";  # hl.dsp.exec_cmd("nautilus")
  # "SUPER + RETURN" = "SUPER + RETURN";  # hl.dsp.exec_cmd(terminal)
  "SUPER + R" = "SUPER + SHIFT + R";  # hl.dsp.exec_cmd("serpantinum reload")
  "SUPER + C" = "SUPER + V";  # hl.dsp.exec_cmd("serpantinum msg toggle clipboard")
  # "SUPER + D" = "SUPER + D";  # hl.dsp.exec_cmd("serpantinum msg toggle launcher")
  # "SUPER + M" = "SUPER + M";  # hl.dsp.exec_cmd("serpantinum msg toggle music")
  # "SUPER + B" = "SUPER + B";  # hl.dsp.exec_cmd("serpantinum msg toggle system")
  # "SUPER + W" = "SUPER + W";  # hl.dsp.exec_cmd("serpantinum msg toggle wallpaper")
  # "SUPER + S" = "SUPER + S";  # hl.dsp.exec_cmd("serpantinum msg toggle calendar")
  # "SUPER + N" = "SUPER + N";  # hl.dsp.exec_cmd("serpantinum msg toggle network")
  "SUPER + V" = null;  # hl.dsp.exec_cmd("serpantinum msg toggle volume")
  # "SUPER + H" = "SUPER + H";  # hl.dsp.exec_cmd("serpantinum msg toggle settings")
  # "SUPER + A" = "SUPER + A";  # hl.dsp.exec_cmd("serpantinum msg toggle autohide")
}
