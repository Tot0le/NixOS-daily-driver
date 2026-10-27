# Troubleshooting and rollback

*Read the rollback ladder **before** a risky change. The first rung that applies is usually enough. Background: [concepts](concepts.md). Procedures: [how-to](how-to.md), [maintenance](maintenance.md).*

## Rollback ladder

The system and the user environment roll back independently.

| What went wrong | Way back |
| --- | --- |
| A system change activated with `nixos-rebuild test` misbehaves | Reboot. `test` is not permanent: the machine returns to the previous generation. Files that Home Manager already wrote in a home directory stay |
| A system change activated with `switch` misbehaves | `sudo nixos-rebuild switch --rollback`, or pick the previous generation in the GRUB menu |
| A Home Manager change misbehaves | Home Manager has no `test` mode: every `switch` is permanent, but earlier generations stay available. Before a risky change run `home-manager generations \| head -3` and note the line of the current generation, which ends in a store path. Going back is running `<that path>/activate` |
| Hyprland starts without shortcuts, bar or keyboard layout | Do not stay in that session. `Ctrl+Alt+F3` opens a text console (`Ctrl+Alt+F2` goes back to the graphical one); log in and run the `activate` script of the earlier generation, or `pkill Hyprland`. In GDM the gear icon at the bottom right offers the GNOME session, which is the safety net: check it is offered before changing the Hyprland configuration |
| The bar is missing inside a working Hyprland session | `SUPER+Return` opens a terminal; `serpantinumd start` starts the shell by hand. To stop it, always use `serpantinum kill` |
| Home Manager overwrote a file you cared about | Files it replaces are renamed with the `.bak` extension (`-b bak`). A `~/.config/home-manager/home.nix` left by the earlier setup is never touched: the system only creates `flake.nix`, and only when it is missing |
| A commit removed something | Everything is in Git. `git log --diff-filter=D --oneline -- <path>` finds the commit that deleted a file, and `git show <commit>^:<path>` prints it as it was |
| A local commit should disappear | Only if it was never pushed: `git reset --hard <hash>` (see the warning below). A `git revert` keeps both commits in the history |

**Never run `nix-collect-garbage -d`** on a machine you may need to roll back: it deletes every old generation, which are the rollback points.

**Before `git reset --hard`, `git status` must be empty.** It discards all uncommitted changes and nothing in Git can bring them back. A shell does not read comments: in a block of commands, a "must print nothing" comment does not stop the next line. Chain with `&&` when one command must gate the next.

## Known pitfalls

### Flakes and Git

- **`error: Path 'hardware-configuration.nix' ... is not tracked by Git`.** Flakes only see tracked files; the file is ignored on purpose. See [maintenance](maintenance.md#build-and-activate-the-system).
- **`daily-driver does not match any input`.** The update was run in `/etc/nixos`. Run it in `~/.config/home-manager`.
- **A change in `/etc/nixos` has no effect in the user environment.** The user flake pins the repository: [how-to](how-to.md#apply-a-change-made-in-this-repository).
- **A change of `layout` in `usersConfigs` has no effect on an existing account.** The layout is only written when the account's flake is created: [maintenance](maintenance.md#add-or-change-an-account).
- **`home-manager` or `nix flake` refuse to run: flakes are disabled.** After a reboot from a `test` activation, the system is back on a generation without flakes. Run `nixos-rebuild test` again, or enable them for one account in `~/.config/nix/nix.conf` (`experimental-features = nix-command flakes`).
- **Evaluation fails with `path ... does not exist`.** A module references a file that was deleted. Search for leftovers before committing a deletion, for example `grep -rn 'conf/hypr' /etc/nixos --include='*.nix'`.
- **A package fails the `noBrokenSymlinks` check** (it happened to `tela-circle-icon-theme` on a newer nixpkgs). Usually the user flake locked a newer nixpkgs than the system: [maintenance](maintenance.md#move-to-a-newer-nixpkgs). As a last resort, `overrideAttrs { dontCheckForBrokenSymlinks = true; }` silences the check at the price of missing icons.
- **zsh expands a glob before the command runs.** `sudo du -sh /boot/EFI/*` fails for lack of permission, and `grep --include=*.qml` fails with `no matches found`. Quote the pattern (`--include='*.qml'`) or use `sudo sh -c '...'`.

### System

- **`No space left on device` during `switch`.** When `/boot` is a small EFI system partition (96 MB on the maintainer's machine, shared with Windows), GRUB copies the new kernel and initrd (about 40 MB) **before** deleting the old ones, so two sets cannot fit as soon as the kernel changes. Any nixpkgs update that moves the kernel is expected to hit this; the flake setup is not the cause.
  - The current generation keeps working: the installer copies kernels first and writes the menu afterwards, so a failed copy leaves the menu intact, and the old kernel and initrd stay in `/boot/kernels`.
  - Deleting the half-copied `*.tmp` kernel that the failed run leaves behind gives a little room, which also matters for Windows updates.
  - `boot.loader.grub.configurationLimit` is expected not to help (all entries share one kernel), and neither is `copyKernels = false` (the copy is automatic with a separate `/boot`). Neither has been tried.
  - **Durable fix, never tried:** put `/boot` on the main partition and mount the EFI partition at `/boot/efi` (`boot.loader.efi.efiSysMountPoint`). It reinstalls the bootloader, and a mistake can prevent the machine from booting, so it needs a dedicated session. Prepare a NixOS live USB stick (the expected repair is to start from it, mount the partitions, run `nixos-enter` and then `nixos-rebuild boot`), keep the BitLocker recovery key if Windows is encrypted, and take backups **copied off the disk**:

    ```bash
    sudo dd if=<EFI partition> of=<backup>/esp-backup.img bs=1M status=progress
    sudo sfdisk -d <disk> | sudo tee <backup>/partition-table.txt > /dev/null
    ```

    `dd` copies the EFI partition (it restores a failed bootloader repair), `sfdisk` dumps the partition table (it restores a resize that went wrong). **Neither backs up personal files:** copy those separately with `rsync`, checking sizes with `du -sh` first.
- **USB devices misbehave after resuming from suspend (AMD A520 chipset).** `configuration.nix` installs a workaround, `/etc/systemd/system-sleep/xhci-fix`, which unbinds and rebinds the XHCI controller around suspend. The PCI address `0000:04:00.0` is written in it and it is installed on every host: adjust or remove it on other hardware.
- **`nbfc_service` exits with status 4 after a switch or test.** `modules/cooling.nix` starts it on every host. On a machine without a supported fan controller it has no configuration to load, and the failure is harmless.

### Home Manager

- **`xdg.configFile."<path>".source` has conflicting definition values.** The same file is defined twice, for example in the user flake's personal section and in a feature. Keep it in one place.
- **A setting changed in `programs.serpantinum.settings` does nothing.** `settings.json` is only written when it does not exist. Change it in the application, or delete the file to apply the Nix value.
- **Nautilus reports a missing `gtk-4.0/gtk.css`.** Home Manager's legacy default imported the GTK 3 theme into GTK 4. `gtk4.theme = null;` in `users/features/gnome-custom.nix` adopts the new behaviour.
- **An error bar appears for a few seconds during `home-manager switch`.** Probably Hyprland reloading while its files are being replaced. `hyprctl configerrors` must print nothing afterwards.

### Hyprland, Serpantinum and shortcuts

- **Serpantinum seems to crash when started in the background (`Daemon is already running. Exiting...`).** A previous daemon is still alive. `pkill quickshell` leaves its helper scripts running; use `serpantinum kill`, then start again.
- **Shortcuts stop working after an update.** A running shell keeps the version it was started with and the `serpantinum` command is now newer: log out and back in.
- **`serpantinum msg workspace N` does nothing.** Under a Lua configuration, its script (`qs_manager.sh`) runs the legacy `hyprctl dispatch workspace N` first. That prints a syntax error but exits with status 0, so the Lua form after the `||` never runs. Workspaces are bound directly in `hyprland-custom.nix`. The legacy `hyprctl dispatch workspace 2` also fails by hand, with a Lua syntax error.
- **A screenshot reports `missing dependencies`.** `pactl` is not on the `PATH`: the `pulseaudio` package must be installed for the user. Serpantinum's Nix package does not provide it.
- **Two bars, or two volume pop-ups, or the volume moves by 10.** Two shells run (an old autostart line launching another `quickshell -p`: `pgrep -af 'quickshell -p'` must show one line), or two bindings act on the same key (a catalog entry such as `pamixer -i 5` plus upstream's `serpantinum volume raise`). Keep volume and media keys in `coveredByUpstream`.
- **A shortcut you moved or disabled has no effect.** `hl.unbind` needs exactly the same string as the original binding, including upper case. `hyprctl binds` does not show commands under Lua: read the generated `~/.config/hypr/config/keybinds.lua` ([shortcuts](shortcuts.md#check-what-is-bound)).
- **A service started by systemd (for example `easyeffects`) lacks the graphical environment.** Home Manager's Hyprland module used to export the session variables to systemd, and it is no longer used here. See [status](status.md#not-verified).

### Applications

- **Every new kitty window opens maximized and hides the others.** kitty stores the last window state in `~/.cache/kitty/main.json` and restores it. `remember_window_size no` in `conf/kitty/kitty.conf` stops that; the stale file can stay.
