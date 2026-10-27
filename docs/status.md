# Status

*Last updated 27 October 2026. Before: [concepts](concepts.md). This page is the only place where doubt is written down: the other pages state what is established. When you check something listed here, update this page in the same commit and date the line.*

Written against NixOS 26.05, Home Manager `release-26.05`, Hyprland 0.55 and Serpantinum v2.3.0.

## Checked against the sources

On 27 October 2026, the file names, options, assertions, scripts and commands that these pages name were compared with the tip of the `flake-migration` branch and with Serpantinum's `master` (version 2.3.0). That covers what the code says. It does not cover how the programs behave when they run: the exit status of `hyprctl dispatch workspace` under a Lua configuration, or the output of `hyprctl binds`, come from tests made on the maintainer's machine.

## Verified

On the maintainer's machine, 26 October 2026:

- Building and activating the user flake, with layouts read from `/etc/nixos`.
- Serpantinum v2.3.0 started by the Hyprland autostart, and the `serpantinum` commands used by the shortcuts.
- Moving and disabling upstream shortcuts through `conf/hyprland-shortcuts.nix`, and adding a shortcut through `~/.config/hypr/local.lua`.
- Switching workspace by key code on an AZERTY keyboard.
- Taking a screenshot once `pactl` is installed.

On 27 October 2026:

- Moving a window to a workspace (`SUPER + SHIFT + <key code>`).

## Not verified

- Moving or disabling a shortcut from `local.lua`. It follows Hyprland's documented `hl.unbind`; adding one works.
- The first login of a freshly created account: the activation script, the first-shell hook, and the seeding of `local.lua`.
- The installation sequence in [install](install.md), including `nixos-rebuild --flake` enabling flakes by itself on a system that does not have them yet.
- Choosing the Hyprland session with an account whose layout does not import `hyprland-custom.nix`, and what Hyprland shows then. No way is known to hide the session entry for some accounts only.
- `home-manager build --flake . --override-input serpantinum <path>` (see [CONTRIBUTING](../CONTRIBUTING.md#serpantinum)).
- Services started by systemd user units under Hyprland (for example `easyeffects`), now that Home Manager's Hyprland module no longer exports the session variables.
- Serpantinum's colour generation for kitty and fastfetch. fastfetch's configuration is a read-only link managed by Home Manager.
- `path:` instead of `git+file:` for the `daily-driver` input: the reason (refusal for users who do not own the repository) was not tested.
- The behaviour of the GRUB installer described in [troubleshooting](troubleshooting.md#system) (copy before delete, menu written last) comes from memory, not from reading the code. The `/boot` repair with `nixos-enter`, and the backups with `dd` and `sfdisk`, have never been run.
- Hyprland's announcement of the Lua configuration (<https://hypr.land/news/26_lua/>) says the older hyprlang syntax stays supported for one or two releases starting with 0.55, then is dropped. This claim was not re-read when these pages were written.

## Known gaps

- **Installing on a new machine** is not supported: `install.sh` and `add_user.sh` predate the flake setup ([install](install.md#about-installsh-and-add_usersh)). `add_user.sh` has not been checked against it either.
- **Per-host configurations.** `hardware-configuration.nix` and `local.nix` are ignored by Git and so invisible to the flake. A `hosts/` directory with one configuration per machine is planned. Until then, anything that `local.nix` sets is not applied unless the file is registered like `hardware-configuration.nix`. That includes its host name, and with it the model-specific fan curve of `modules/cooling.nix`, which is selected on the host name `nixos-victus`. This follows from how flakes read files and has not been checked.
- **Fan control.** `modules/cooling.nix` starts `nbfc_service` on every host. The fan shortcuts (`fans` in the catalog) are bound for GNOME for every account and are not bound under Hyprland at all. Both are to be restricted to machines that have a fan controller.
- **A suspend workaround for one chipset** (`xhci-fix`, AMD A520, fixed PCI address) is installed on every host.
- **A French keyboard is built in** under Hyprland: `kb_layout = "fr"` and the AZERTY key codes of the workspaces are written in `users/features/hyprland-custom.nix`, with no setting for them.
- **No automatic screen lock under Hyprland.** This repository configures none: `conf/hypr/hypridle.nix` is not imported by any module, and Serpantinum's own idle module is not configured here (its default behaviour has not been checked).
- **Six Serpantinum actions without a shortcut:** `settings`, `monitors`, `focustime`, `togglePerf`, `toggleDraw` and `toggleTimer`. `local.lua` can add them.
- **No per-user opt-out** of what a layout installs. Splitting the long package list of `all-Feature.nix` into smaller features is planned.
- **Adding another Quickshell theme** needs one more input in `users/templates/home-flake.nix` (existing accounts must add the line by hand), a feature file, and a choice in the layout.
