# Contributing

## This repository

- Code, comments, commit messages and documentation are in English. Comments explain *why*, not *what*.
- Commit messages follow `type(scope): summary` (`feat`, `fix`, `chore`, `refactor`, `docs`), one subject per commit, for example `fix(kitty): stop restoring the last window state`.
- Do not commit the `result` link left by a build, and do not commit the registered `hardware-configuration.nix` (see [maintenance](docs/maintenance.md#build-and-activate-the-system)). Do not use `git commit -a`.
- Serpantinum is a flake input and is never copied into this repository.
- If you check something listed as unverified in [docs/status.md](docs/status.md), update that page in the same commit and date the line. Doubt is written there and nowhere else; the other pages state what is established.

## Serpantinum

Serpantinum is developed by ilyamiro. Fixes go to [its repository](https://github.com/ilyamiro/serpantinum); read its pull request template before opening one, since the rules are his and can change.

To try a change to Serpantinum with this setup, point your user flake at your local clone instead of GitHub. The option does not modify `flake.nix` or `flake.lock`:

```bash
cd ~/.config/home-manager
home-manager build --flake . --override-input serpantinum <path to your clone>
rm -f result
```

While a pull request is open and you want to use it day to day, you can point the `serpantinum` input of your user flake at your branch (`github:<you>/serpantinum/<branch>`). Put it back on `github:ilyamiro/serpantinum` once it is merged.
