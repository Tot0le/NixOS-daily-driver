# Concepts

*Read this first. Next: [install](install.md) to set up a machine, [how-to](how-to.md) to use your account, [maintenance](maintenance.md) to administer the machine.*

This page explains how the pieces fit together and why. It contains no procedures and no status: those live in the other pages.

## Why flakes

A flake is a directory with a `flake.nix` that declares where its dependencies come from (`inputs`) and what it produces (`outputs`), plus a `flake.lock` that pins the exact revision of every input. It plays the same role as a `package.json` with its lock file: the system builds the same way tomorrow as today, and an update is a deliberate act (`nix flake update <input>`), never a surprise.

One rule explains several oddities in these pages: **a flake that lives in a Git repository only sees files tracked by Git.** Anything in `.gitignore` is invisible to it. The one exception used here is the `daily-driver` input described below, which is a plain directory snapshot and also sees uncommitted files.

## The path of a change

```text
/etc/nixos                          this repository
  flake.nix, configuration.nix      the system
  users/                            layouts, features, templates
     |
     |-- nixos-rebuild ---------------------> the system          (sudo)
     |
     `-- pinned as input "daily-driver" in each user's flake.lock
            |
   ~/.config/home-manager/flake.nix           one per user, created once
     inputs: nixpkgs, home-manager, serpantinum, daily-driver
            |
            `-- home-manager switch --------> that user's home    (no sudo)
                  |-- packages, dotfiles, zsh, kitty, ...
                  `-- if the layout imports hyprland-custom.nix:
                        Serpantinum and ~/.config/hypr/
```

| What changed | Who is affected | How it is applied |
| --- | --- | --- |
| A layout, a feature or a catalog file in `/etc/nixos` | Each user, separately | The user, in their own flake: [how-to](how-to.md#apply-a-change-made-in-this-repository) |
| `configuration.nix` or `flake.nix` | The whole system | An administrator: [maintenance](maintenance.md#build-and-activate-the-system) |
| The Serpantinum version | One user, through their own pin | The user: [how-to](how-to.md#update-serpantinum) |
| `~/.config/hypr/local.lua` | That user's Hyprland | `hyprctl reload`: [shortcuts](shortcuts.md#personal-shortcuts-locallua) |

## Two levels, two flakes

| Level | File | Describes | Built with |
| --- | --- | --- | --- |
| System | `/etc/nixos/flake.nix` | Kernel, services, GNOME, the Hyprland session entry, system users. One `nixosConfigurations.<host>` | `nixos-rebuild` (needs `sudo`) |
| User | `~/.config/home-manager/flake.nix` | One account's packages, dotfiles and shell, through Home Manager | `home-manager` (no `sudo`) |

**System flake.** Its only input is `nixpkgs` (`nixos-26.05`). The configuration is named after the host (`nixos`), which must match `networking.hostName`. Serpantinum is not an input of the system flake: only users need it. Flakes are enabled system-wide with `nix.settings.experimental-features`; that setting only exists in a system generation that has been activated.

**User flake.** Home Manager is *not* a NixOS module here, on purpose: with that design a user could edit their configuration but could not apply it without `sudo`. Instead each user owns a small flake:

- It is created **once**, at system activation, by `system.activationScripts.setupUserHomes` in `configuration.nix`, from `users/templates/home-flake.nix` (the placeholders `@USERNAME@` and `@LAYOUT@` are filled in). After that the file belongs to the user and is never overwritten. Anything personal goes below the line `Personal additions go below this line`.
- Its inputs are `nixpkgs`, `home-manager` (following `nixpkgs` to avoid a second copy), `serpantinum`, and **`daily-driver`**.
- `daily-driver` is this repository as checked out in `/etc/nixos`, declared as `path:/etc/nixos` with `flake = false`: it is read as a plain source tree, not as a flake. `path:` is used instead of `git+file:`, which can refuse users who do not own the repository. The name is historical and misleading.
- The user's `flake.lock` pins the contents of `/etc/nixos`, so **a change in the repository reaches a user only after `nix flake update daily-driver`**. The snapshot includes uncommitted changes.
- The first activation is started by a hook in `environment.interactiveShellInit` when a user opens a terminal and finds a flake but no `home-manager` command (see [how-to](how-to.md#first-time-on-an-account)).

## Layouts and features

Everything a user can have lives in this repository, under `users/`:

- `users/features/*.nix`: Home Manager modules, one concern each (`curseforge`, `gnome-custom`, `hyprland-custom`, `kathara`, `kitty-terminal`, `zsh-shell`).
- `users/layouts/*.nix`: bundles of features. `all-Feature.nix` imports everything, `simple.nix` the basics.
- `users/templates/`: files copied once, not modules: the skeleton of the user flake (`home-flake.nix`) and the starting point of a user's Hyprland overrides (`hypr-local.lua`).
- Each account is mapped to a layout in `usersConfigs` (`configuration.nix`), which is also what fills `@LAYOUT@`.

A feature only exists for a user if their layout imports it. In particular **only layouts that import `hyprland-custom.nix` get the Hyprland configuration and Serpantinum**. Home Manager's own Hyprland module is not used. The Hyprland *session* is registered at system level (`programs.hyprland.enable`, which also provides polkit and portals), so it appears in the GDM login screen for every account.

Modules only add up: a user cannot remove something a layout already installs without editing that layout.

## The desktop shell

Two different things are called a shell:

- The command-line shell (zsh) interprets what is typed in a terminal. It is configured by `users/features/zsh-shell.nix` and is unrelated to what follows.
- A desktop shell is the graphical layer around the windows: bar, launcher, notifications, volume popup, lock screen, system panel, wallpaper picker. GNOME Shell plays this role under GNOME. Hyprland only places and draws windows, so under Hyprland Serpantinum plays it.

Serpantinum is consumed as a flake input. Nothing of it is copied into this repository, so `nix flake update serpantinum` updates the shell and the compositor configuration together.

`users/features/hyprland-custom.nix` wires it in:

1. **Enables the shell for the user:** `programs.serpantinum.enable = true` with `systemd.enable = false`. The default systemd unit is tied to `graphical-session.target` and would also start in a GNOME session; the Hyprland autostart (`serpantinumd start`) launches it instead.
2. **Links the upstream compositor configuration.** `compositors/hyprland/config` is taken from the source tree the Serpantinum package was built from (`config.programs.serpantinum.package.src`, because the package itself does not install `compositors/`) and linked as `~/.config/hypr/config`. Its `keybinds.lua` is rewritten at build time according to `conf/hyprland-shortcuts.nix` (see [shortcuts](shortcuts.md)).
3. **Generates `~/.config/hypr/hyprland.lua`:** the upstream entry point followed by this repository's overrides, so that they win:
   - `kb_layout = "fr"`: upstream defaults to a US layout. This stays until upstream offers a setting for it.
   - One `hl.unbind` followed by `hl.bind` for each entry of the shortcut catalog.
   - Workspaces bound by **physical key code** (`code:10` to `code:19`) instead of digit names, because on an AZERTY keyboard the digit row needs Shift. They are bound straight to Hyprland (`hl.dsp.focus`, `hl.dsp.window.move`) and not through `serpantinum msg workspace N` (see [troubleshooting](troubleshooting.md#hyprland-serpantinum-and-shortcuts)). The upstream digit bindings are unbound first.
   - `require("local")`, which loads the user's own overrides.
4. **Seeds `~/.config/hypr/local.lua`** from `users/templates/hypr-local.lua` when it does not exist. The file belongs to the user afterwards.
5. **Installs the tools the shell and the shortcuts call:** `cliphist`, `easyeffects` and `playerctl` (upstream autostart and keybindings), `pamixer` (the volume entries of the shared catalog, used by GNOME), `pulseaudio` (only for `pactl`, which `screenshot.sh` requires and the upstream Nix package does not put on its `PATH`; the server stays disabled), the command-line tools `jq`, `tree`, `ripgrep` and `fd`, and the Nerd Fonts used by the shell's icons.

Hyprland reads either `hyprland.lua` or `hyprland.conf`, not both, and a `hyprland.lua` wins when it exists: do not put one in `~/.config/hypr/` by hand. This setup uses Lua only.

The Serpantinum NixOS module is not used. It only enables NetworkManager, Bluetooth, `i2c`, `power-profiles-daemon`, PipeWire and one font, all as defaults; the system configuration already provides the services this machine needs. Add `hardware.i2c.enable = true;` only to control the brightness of an external monitor.

## Version pinning

The system and each user have their own `flake.lock`. Nothing changes until one of them is updated on purpose, which is also why a newer Serpantinum release never reaches a desktop by surprise. The pin that matters for the desktop is in the **user** flake.

The locks can drift apart: a user flake that locks a newer nixpkgs than the system may fail to build something the system builds. The procedure that keeps them aligned is in [maintenance](maintenance.md#move-to-a-newer-nixpkgs).

Home Manager's `home.stateVersion` is kept at `25.11` on purpose: it records the release the user's data was created with, and Home Manager warns about the defaults that change with 26.05 instead of applying them silently.

## State that lives outside Nix

Some settings are deliberately not managed by Nix, because an application rewrites them or because they are personal:

- `~/.config/serpantinum/settings.json`: written by the Home Manager module **only if it does not exist yet**. Changing `programs.serpantinum.settings` later has no effect while the file exists; use the application's settings window, or delete the file to apply the Nix values again.
- `~/.config/hypr/local.lua`: a user's own Hyprland overrides, never overwritten.
- `~/.config/shortcuts-override.json`: GNOME shortcut changes made in the GNOME settings (see [shortcuts](shortcuts.md#the-gnome-side)).
- `~/.config/git/identity`: the Git name and e-mail, for accounts whose layout is `all-Feature`. The repository contains no identity; `user.useConfigOnly = true` makes Git refuse to commit without one instead of guessing.
- `hardware-configuration.nix` and `local.nix`: machine-specific, listed in `.gitignore`.

What is verified and what is not: [status](status.md).
