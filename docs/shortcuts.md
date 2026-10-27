# Shortcuts

*Before: [concepts](concepts.md). Applies to accounts whose layout imports `hyprland-custom.nix`. Needs no `sudo` unless you edit a shared file in `/etc/nixos`.*

Under Hyprland, shortcuts come from Serpantinum's own bindings (the base) plus three places that this repository controls. Pick the place by scope.

| You want to | Edit | Applies to | Then |
| --- | --- | --- | --- |
| Move or disable a Serpantinum shortcut | `conf/hyprland-shortcuts.nix` | every user whose layout imports `hyprland-custom.nix` | apply the change ([how-to](how-to.md#apply-a-change-made-in-this-repository)), then `hyprctl reload` |
| Add or change an application shortcut that GNOME shows too | `conf/shortcuts.list.nix` | GNOME and Hyprland | apply the change, then `hyprctl reload` |
| Add, move or disable a shortcut for one user only | `~/.config/hypr/local.lua` | that user | `hyprctl reload` |

## Move or disable a Serpantinum shortcut

`conf/hyprland-shortcuts.nix` lists every shortcut of Serpantinum's `keybinds.lua` (as of v2.3.0). A line left commented out is unchanged. The left side is the upstream key exactly as written there, case included. Uncomment a line and put the new key on the right, or `null` to disable it. The trailing comment shows what the shortcut runs.

```nix
  "SUPER + R" = "SUPER + SHIFT + R";  # hl.dsp.exec_cmd("serpantinum reload")
  "SUPER + V" = null;                 # hl.dsp.exec_cmd("serpantinum msg toggle volume")
```

At build time, `keybinds.lua` from the pinned upstream source is rewritten accordingly. The build **fails with an explicit message** instead of producing a wrong shortcut when:

- a key you changed is no longer bound upstream (renamed or removed in a newer release);
- the new key is already used by an upstream shortcut that you did not also move or disable;
- two shortcuts end up on the same key (remaps and catalog together).

Workspace shortcuts are not in the list: they are bound by key code in `users/features/hyprland-custom.nix` (see [concepts](concepts.md#the-desktop-shell)).

The list is not regenerated when Serpantinum is updated. A shortcut added upstream does not appear in it until you read the difference ([how-to](how-to.md#update-serpantinum)) and add a line.

## Application shortcuts: the catalog

`conf/shortcuts.list.nix` is a table of `name = [ "Display name" "command" "binding" ]` in groups (`commonApps`, `terminalTools`, `graphicTools`, `fans`). The binding uses GNOME's syntax: `<Super>f`, `<Ctrl><Shift>o`, and `, XF86AudioStop` (a comma and a space) for a key without modifier.

The same entry feeds GNOME at session start, and Hyprland at build time. For Hyprland it is converted to Lua key syntax (`<Super><Shift>f` becomes `SUPER + SHIFT + F`; a single letter is upper-cased because `hl.unbind` is case-sensitive and upstream writes `SUPER + F`), and the upstream binding on the same key is removed before the catalog one is bound.

Two things are not pushed to Hyprland:

- The entries listed in `coveredByUpstream` in `users/features/hyprland-custom.nix` (volume and media keys). Upstream sends them through the shell so that its on-screen display stays in sync; with both, the volume rose by 10 per key press. They stay in the catalog for GNOME.
- The `fans` group, which only GNOME uses. Under Hyprland the fan shortcuts are not bound.

## Personal shortcuts: `local.lua`

`~/.config/hypr/local.lua` belongs to the user and is loaded last (the generated `hyprland.lua` ends with `require("local")`). It is not versioned and needs no rebuild: edit it, then run `hyprctl reload`.

A new account gets it from `users/templates/hypr-local.lua` the first time its Home Manager configuration is activated, with every example commented out. An account created before this template existed keeps the one-line file it was given.

```lua
-- Add a shortcut
hl.bind("SUPER + P", hl.dsp.exec_cmd("firefox --private-window"))

-- Move a shortcut: free the old key, then bind the new one
pcall(hl.unbind, "SUPER + S")
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("serpantinum msg toggle calendar"))

-- Disable a shortcut
pcall(hl.unbind, "SUPER + A")
```

`pcall` keeps an unbind of a key nothing is bound to from aborting the file.

## Key strings

- Modifiers are `SUPER`, `CTRL`, `SHIFT` and `ALT`, joined with ` + `: `SUPER + SHIFT + R`.
- A key is a name (`Q`, `RETURN`, `Print`, `XF86AudioMute`) or a physical code (`code:10`). Codes do not depend on the keyboard layout: on AZERTY the digit row needs Shift, so workspaces use `code:10` to `code:19`.
- `hl.unbind` needs exactly the same string as the original `hl.bind`, case included, and removes every binding on that key registered before it.

## Check what is bound

Under a Lua configuration `hyprctl binds` lists keys and modifiers but not the commands (it shows `dispatcher: __lua`), so searching it for a command finds nothing. Read the generated files instead; they are read-only links into the Nix store:

```bash
less ~/.config/hypr/config/keybinds.lua
less ~/.config/hypr/hyprland.lua
hyprctl configerrors
```

`hyprctl configerrors` must print nothing after a reload.

## The GNOME side

- Shortcuts changed in the GNOME keyboard settings are stored in `~/.config/shortcuts-override.json` and re-applied to GNOME only. They do **not** propagate to Hyprland.
- That file also keeps entries you removed from the catalog. After deleting an entry from `conf/shortcuts.list.nix`, delete it in the GNOME keyboard settings too, otherwise GNOME keeps it.

## Do not make desktop-wide a shortcut that applications use

`Ctrl+Shift+O` and `Ctrl+Shift+P` used to be catalog entries (terminal opacity). Being desktop-wide, they shadowed the same keys in other applications (Eclipse's "organize imports"). They now live in `conf/kitty/kitty.conf`, where they only fire when kitty has focus.
