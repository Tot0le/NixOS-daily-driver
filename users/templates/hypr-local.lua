-- Personal Hyprland overrides, loaded last. Apply with: hyprctl reload

-- Add a shortcut
-- hl.bind("SUPER + P", hl.dsp.exec_cmd("firefox --private-window"))

-- Move a shortcut: free the old key, then bind the new one
-- pcall(hl.unbind, "SUPER + S")
-- hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("serpantinum msg toggle calendar"))

-- Disable a shortcut
-- pcall(hl.unbind, "SUPER + A")

-- Change a Hyprland setting for this user only
-- hl.config({ general = { gaps_in = 2, gaps_out = 4 } })
