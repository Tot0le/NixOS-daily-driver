# Maintenance

*Before: [concepts](concepts.md). For whoever administers the machine: everything here needs `sudo`, or changes what every user gets. Per-user tasks are in the [how-to](how-to.md). If something goes wrong, read the [rollback ladder](troubleshooting.md#rollback-ladder) first.*

## Build and activate the system

Flakes only see Git-tracked files, and `hardware-configuration.nix` is ignored on purpose. Until a `hosts/` directory exists, register the file without its content for the duration of the commands, and unregister it **before committing**:

```bash
cd /etc/nixos
git add -f -N hardware-configuration.nix
nixos-rebuild build --flake .#nixos
nix store diff-closures /run/current-system ./result
sudo nixos-rebuild test --flake .#nixos    # optional: activate until the next reboot
git reset -- hardware-configuration.nix
rm -f result
```

Keep the file registered until every command that evaluates the flake has finished, `test` included.

- `build` changes nothing.
- `test` activates the result until the next reboot; a reboot returns to the previous generation.
- `switch` (`sudo nixos-rebuild switch --flake .#nixos`) makes it permanent. It can fail when `/boot` is too small: see [troubleshooting](troubleshooting.md#system).

After a reboot from a `test` activation, the system is back on a generation without flakes: see [troubleshooting](troubleshooting.md#flakes-and-git).

Do not use `git commit -a`: it would take the registered hardware file with it.

## Add or change an account

Accounts are the entries of `usersConfigs` in `configuration.nix`:

```nix
newname = { fullName = "New Name"; isAdmin = false; layout = "simple"; };
```

Build and activate the system as above. The system creates the Linux account (without a password) and, at activation, the account's `~/.config/home-manager/flake.nix`. Then give it a password with `sudo passwd newname`. The account's first terminal starts its first activation (see [how-to](how-to.md#first-time-on-an-account)).

`add_user.sh` automates the first step; it has not been checked against the flake setup ([status](status.md#known-gaps)).

Changing an entry later has two different effects. `isAdmin` takes effect at the next system activation. `layout` is only used to **create** the account's flake, which is never overwritten: for an existing account, change the line `"${daily-driver}/users/layouts/<layout>.nix"` in its `~/.config/home-manager/flake.nix`, then apply the change as described in the [how-to](how-to.md#apply-a-change-made-in-this-repository).

## Move to a newer nixpkgs

Update the system first, then bring each user to the same revision; otherwise a user flake locks a newer nixpkgs than the system, which can fail to build something the system builds (see [troubleshooting](troubleshooting.md#flakes-and-git)).

```bash
cd /etc/nixos
nix flake update nixpkgs
jq -r '.nodes.nixpkgs.locked.rev' flake.lock
```

Then, for each user, with `<rev>` the revision printed above:

```bash
cd ~/.config/home-manager
nix flake lock --override-input nixpkgs github:nixos/nixpkgs/<rev>
```

A kernel update can also fill a small `/boot` partition (see [troubleshooting](troubleshooting.md#system)).
