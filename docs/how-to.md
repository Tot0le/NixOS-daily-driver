# How to use and update your environment

*Before: [concepts](concepts.md). Everything here runs as your own user, without `sudo`. Next: [shortcuts](shortcuts.md). If something goes wrong: [troubleshooting](troubleshooting.md). System-level changes: [maintenance](maintenance.md).*

Run commands as they are, in the directory shown. A command that only builds changes nothing on the machine until you run a `switch`.

## First time on an account

Open a terminal. When your flake exists but the `home-manager` command does not, a hook starts the first activation for you. If it does not, run it yourself:

```bash
nix run github:nix-community/home-manager/release-26.05 -- switch --flake ~/.config/home-manager -b bak
```

The run ends without an error, and `home-manager generations | head -1` then shows the new generation.

## Apply a change made in this repository

Your flake pins the contents of `/etc/nixos` in its own `flake.lock`, so after any change there, run in **your flake directory** (not in `/etc/nixos`):

```bash
cd ~/.config/home-manager
nix flake update daily-driver
home-manager switch --flake . -b bak
```

`daily-driver` is the input that points at `/etc/nixos`; the first command moves only that pin, so `nixpkgs` stays where it was. `-b bak` renames a file Home Manager would overwrite to `<name>.bak` instead of failing. Run from `/etc/nixos`, the first command fails with `daily-driver does not match any input`, because the system flake has no such input.

If the change touches the Hyprland configuration, run `hyprctl reload` afterwards.

## Check a change without applying it

Replace the last command with a build, and delete the link it leaves:

```bash
home-manager build --flake .
rm -f result
```

## Add your own settings

Your flake belongs to you and is never overwritten. Put anything personal below the line `Personal additions go below this line` in `~/.config/home-manager/flake.nix`. Your Hyprland shortcuts go in `~/.config/hypr/local.lua` (see [shortcuts](shortcuts.md#personal-shortcuts-locallua)).

You cannot remove something your layout installs without editing the layout, which is an administrator's change (see [concepts](concepts.md#layouts-and-features)).

## Add software

Everything here goes in your own flake, `~/.config/home-manager/flake.nix`, and affects only your account. An addition for every account goes through a layout or a feature, which is an administrator's change. Apply any of the edits below with `home-manager switch --flake . -b bak`, in `~/.config/home-manager`.

### A package from nixpkgs

This is the usual case, even for an application that also has its own flake. Find the name with `nix search nixpkgs <word>` or on <https://search.nixos.org/packages>, then add a module below the line `Personal additions go below this line`, before the closing `];` of the `modules` list:

```nix
          # Personal additions go below this line
          { home.packages = [ pkgs.htop pkgs.btop ]; }
```

`pkgs` is already defined in the file and allows unfree packages. Lists add up: a second `{ home.packages = [ ... ]; }` module also works, and both come in addition to what your layout installs. Entries in a Nix list are separated by spaces, not commas.

### An application that only exists as a flake

Three edits in `flake.nix`:

1. Declare the input, next to the others in `inputs`:

   ```nix
       monapp.url = "github:author/monapp";
   ```

   If the application's own flake has a `nixpkgs` input, `monapp.inputs.nixpkgs.follows = "nixpkgs";` makes it use yours instead of downloading a second copy, as `home-manager` does in the template.
2. Add its name to the arguments of `outputs`, next to `serpantinum`:

   ```nix
     outputs = { nixpkgs, home-manager, daily-driver, serpantinum, monapp, ... }:
   ```
3. Use it below the personal line. Most flakes export a package:

   ```nix
             { home.packages = [ monapp.packages.x86_64-linux.default ]; }
   ```

   The exact name differs from one flake to the next: `nix flake show github:author/monapp` lists what it exports. A flake that exports a Home Manager module instead (as Serpantinum does with `homeManagerModules.default`) goes straight into the `modules` list, and its own documentation says which options it adds.

The switch records the new input in your `flake.lock`. Update it later on its own with `nix flake update monapp`. To remove the software, delete the lines and switch again; the previous generation stays available ([rollback ladder](troubleshooting.md#rollback-ladder)).

Nothing here changes the system flake, which only has `nixpkgs`: software for every account, or a system service, is an administrator's change in `/etc/nixos`.

## Update Serpantinum

Nothing changes in your desktop until you update your pin, so new upstream shortcuts never arrive by surprise. The pin that matters is the one in **your** flake.

1. **Read what changed.** Use a clone of the upstream repository, only to read code: `git pull` there does not change what is installed. Set `clone` to its path:

   ```bash
   clone=<path to your clone of ilyamiro/serpantinum>
   old=$(jq -r '.nodes.serpantinum.locked.rev' ~/.config/home-manager/flake.lock)
   git -C "$clone" pull --ff-only
   git -C "$clone" log --oneline "$old"..origin/master | head -20
   git -C "$clone" diff "$old" origin/master -- CHANGELOG.md compositors/hyprland/config/keybinds.lua
   ```

   Look for shortcuts that appeared, moved or were renamed, and check that none of the keys listed in `conf/hyprland-shortcuts.nix` changed meaning. The build also fails by itself if a key you moved was renamed or removed upstream.

2. **Update the pin and only build:**

   ```bash
   cd ~/.config/home-manager
   nix flake update serpantinum
   home-manager build --flake .
   rm -f result
   ```

3. **Note your current generation** (see the [rollback ladder](troubleshooting.md#rollback-ladder)), then apply from a session that is **not** the Hyprland session (a console with `Ctrl+Alt+F3`, or GNOME), because a faulty Lua configuration can leave Hyprland without shortcuts:

   ```bash
   home-manager switch --flake ~/.config/home-manager -b bak
   ```

4. **Log out and back in to Hyprland.** A running shell keeps the version it was started with, and a `serpantinum` command from a newer version may not find it. Then run `hyprctl configerrors`: it must print nothing.

To know which version is installed, read the store path: `readlink -f "$(command -v serpantinum)"` contains it. `serpantinum -V` is not reliable here, because it reads a state file written at first launch.

If upstream adds a module to `hyprland.lua`, nothing needs to change: the file is read from the pinned source, not retyped. A shortcut or settings target you use may be renamed in a release (`guide` became `settings` in v2.3.0), so test your own shortcuts by hand after an update.
