# NixOS daily driver

A declarative NixOS setup for a machine shared by several people: GNOME for everyone, an optional Hyprland session running the [Serpantinum](https://github.com/ilyamiro/serpantinum) desktop shell, and one Home Manager environment per user that each user can edit and apply without `sudo`.

> **Status.** The work lives on the `flake-migration` branch and is not merged into `main` yet. The system flake builds. Installing on a new machine is not supported yet: the setup scripts predate the flake, and the manual sequence in [docs/install.md](docs/install.md) has never been run end to end. What is verified and what is not is listed in [docs/status.md](docs/status.md).

## Where to start

| You are | Read |
| --- | --- |
| Setting this up on a machine | [install](docs/install.md), then [concepts](docs/concepts.md) |
| Using this machine with your own account | [concepts](docs/concepts.md) for the picture, then [how-to](docs/how-to.md) and [shortcuts](docs/shortcuts.md) |
| Administering it (anything that needs `sudo`) | [concepts](docs/concepts.md), then [maintenance](docs/maintenance.md) and [status](docs/status.md) |
| Facing a problem | [troubleshooting](docs/troubleshooting.md), starting with its rollback ladder |
| Contributing here or to Serpantinum | [CONTRIBUTING](CONTRIBUTING.md) |
| Maintaining this repository | [maintainer notes](docs/maintainer-notes.md) |

## Repository layout

```text
flake.nix, flake.lock    system flake (input: nixpkgs 26.05)
configuration.nix        accounts, services, GNOME, the Hyprland session entry
modules/                 system modules (cooling, docker, keyd, monitoring, ...)
users/layouts/           what each kind of account gets
users/features/          building blocks the layouts import
users/templates/         files copied once into a new user's home
conf/                    shortcut catalog, Hyprland shortcut remaps, application settings
scripts/                 helper commands installed for users
templates/               Nix environment kits for development projects
install.sh, add_user.sh  setup scripts from before the flake setup (see docs/install.md)
docs/                    documentation
```
