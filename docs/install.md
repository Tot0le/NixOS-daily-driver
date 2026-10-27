# Install on a new machine

*Before: [concepts](concepts.md). **Not supported yet.** The two scripts at the root of the repository, `install.sh` and `add_user.sh`, predate the flake setup and should not be used (see below). The sequence on this page follows from how the repository works, but it has never been run end to end on a fresh machine ([status](status.md)). Day-to-day use afterwards: [how-to](how-to.md).*

## Requirements

- A machine already running NixOS, with network access. The flake builds `x86_64-linux` only.
- UEFI boot: the configuration uses GRUB with EFI support and `os-prober`.

## 1. Get the repository

The configuration lives in `/etc/nixos`. Until the migration is merged, use the `flake-migration` branch. Keep the hardware profile of the machine: it is machine-specific and ignored by Git.

```bash
nix-shell -p git
sudo mv /etc/nixos /etc/nixos.orig
sudo git clone --branch flake-migration https://github.com/Tot0le/NixOS-daily-driver /etc/nixos
sudo cp /etc/nixos.orig/hardware-configuration.nix /etc/nixos/
```

If the machine has no `hardware-configuration.nix`, `sudo nixos-generate-config --show-hardware-config | sudo tee /etc/nixos/hardware-configuration.nix` creates one.

## 2. Adapt it to your machine

Open `/etc/nixos/configuration.nix` and go through what follows before the first build.

- **Accounts.** `usersConfigs` lists the accounts. It ships with two accounts: `alice` (layout `simple`) and the maintainer's own (`isAdmin = true`, layout `all-Feature`). Replace them with yours:

  ```nix
  usersConfigs = {
    yourname = { fullName = "Your Name"; isAdmin = true; layout = "all-Feature"; };
  };
  ```

  `isAdmin` adds the account to `wheel` (it can use `sudo`), so keep at least one administrator. The layout decides what the account gets (see [concepts](concepts.md#layouts-and-features)): only `all-Feature` includes Hyprland and Serpantinum.
- **Host name.** The flake exposes one configuration, `nixosConfigurations.nixos`, and the comment in `flake.nix` says its name must match `networking.hostName`. `configuration.nix` sets that to `nixos` by default. Keep it, or change both.
- **Choices written for the maintainer's machine.** Review these and change what does not suit you:
  - Time zone `Europe/Paris`, French console and X keyboard layout, `en_US` locale with `fr_FR` formats. Hyprland has its own French layout (`kb_layout = "fr"`) and AZERTY workspace key codes in `users/features/hyprland-custom.nix`.
  - Steam, Lunar Client, LibreOffice and Firefox in the system packages; TCP port 25565 open in the firewall.
  - A weekly garbage collection that deletes generations older than 14 days.
  - A suspend workaround for an AMD A520 USB controller (`environment.etc."systemd/system-sleep/xhci-fix"`), with the PCI address `0000:04:00.0` written in it. It applies to every host: remove it unless it matches your hardware.
  - The `modules/` listed in `imports`: `cooling.nix` drives a laptop fan controller (NBFC) and its fan curve is only selected on the host name `nixos-victus`.

## 3. Build the system

Flakes only see Git-tracked files, and `hardware-configuration.nix` is ignored on purpose, so register it without its content for the build:

```bash
cd /etc/nixos
sudo git add -f -N hardware-configuration.nix
sudo nixos-rebuild test --flake .#nixos
```

`test` activates the system until the next reboot, so a reboot undoes it. When the result is what you want, run `sudo nixos-rebuild switch --flake .#nixos` to make it permanent, then `sudo git reset -- hardware-configuration.nix` before committing anything. If `switch` fails with `No space left on device`, see [troubleshooting](troubleshooting.md#system).

## 4. Set up the accounts

The system activation creates `~/.config/home-manager/flake.nix` for every account of `usersConfigs` that does not have one yet.

```bash
sudo passwd yourname
sudo chown -R yourname:users /etc/nixos
```

The first command gives the account a password (the accounts are created without one). The second lets the administrator use Git in `/etc/nixos`.

Then log in through GDM and open a terminal. The first activation of the user environment starts by itself (see [how-to](how-to.md#first-time-on-an-account)); close and reopen the terminal when it says so. For an account whose layout includes Hyprland, the gear icon on the login screen offers the Hyprland session next to GNOME.

## About `install.sh` and `add_user.sh`

They are interactive scripts written before the flake setup, and several of their steps no longer fit:

- `install.sh` edits the line `mainuser = {` of `configuration.nix`, which no longer exists, so the account you type is not added to `usersConfigs`.
- It writes the host name to `local.nix`, an ignored file that a flake cannot see, and it stages files with `git add .`, which skips ignored files.
- Both scripts finish with a plain `nixos-rebuild switch` instead of building the flake explicitly.

To add an account to an installed machine, see [maintenance](maintenance.md#add-or-change-an-account).
