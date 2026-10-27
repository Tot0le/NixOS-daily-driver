# Maintainer notes

*The only page written for one person: you, the maintainer. It holds what is specific to your machine and what is left to do, so that the other pages can stay about the project. Delete a line when it is done.*

## To do before merging `flake-migration` into `main`

1. **Squash the branch** into a few clean commits (a merge with `git merge --squash`, or an interactive rebase). The commit hashes you may have noted in other files will not survive it; the documentation cites none.
2. **Remove `conf/hypr/`** (`colors.conf`, `config/*.conf`, `hypridle.nix`). It was still on the branch on 27 October 2026, and no module imports it. Search for leftovers first: `grep -rn 'conf/hypr' . --include='*.nix'`.
3. **Remove the `quickshellApps` block** of `conf/shortcuts.list.nix` (line 22). `grep -rn quickshellApps .` finds only its definition.
4. **Rewrite or remove `install.sh` and `add_user.sh`**, then update [install](install.md) and the `Installing on a new machine` gap in [status](status.md#known-gaps). Decide with it how `hosts/` should look.
5. **Rename the `daily-driver` input.** Its name is historical and misleading; it appears in `users/templates/home-flake.nix`, in every existing user flake (the line is never overwritten, so each account needs the change by hand), and in the docs.
6. **Add a "what's new" command** that prints the changes between the locked Serpantinum revision and upstream's `master` (the commands are in the [how-to](how-to.md#update-serpantinum)).
7. **Decide the open questions:**
   - an automatic lock under Hyprland (Serpantinum's idle interface limited to locking, or your own `hypridle` with `lock_cmd = "serpantinum lock"`);
   - what to do with the six actions without a shortcut ([status](status.md#known-gaps));
   - whether Serpantinum's colour generation should drive kitty and fastfetch.
8. **Choose a license for this repository.** The root has no `LICENSE` file. Serpantinum is inconsistent on its side: its `LICENSE.md` is the AGPL-3.0, while its Nix package metadata says MIT.
9. **Work through the "Not verified" list** in [status](status.md#not-verified), and move each line you check to "Verified" with its date.

## Your machine

- **`/boot`.** The EFI system partition is 96 MB and shared with Windows, so `switch` fails and the system is only activated with `test`. The old kernel and initrd (6.18.42) are still in `/boot/kernels`. The durable fix and its preparation are in [troubleshooting](troubleshooting.md#system); what is specific to you is that the EFI partition is `/dev/nvme0n1p1` and the disk `/dev/nvme0n1`. About 23 GB of personal data must be copied separately before that session.
- **Suspend.** Automatic suspend hard-locks the machine until it is powered off, because of the AMD A520 XHCI controller. Nothing in the repository disables it, so keep it off in your own settings: in Serpantinum's idle tab, if you enable it, keep the suspend action off and only the lock on.
- **Fan curve.** `modules/cooling.nix` applies the HP Victus curve only when the host name is `nixos-victus`. If you want it under the flake, register your `local.nix` the way you do `hardware-configuration.nix` (`git add -f -N local.nix`), and check which package the build uses.
- **Firefox.** If a site renders a black page while a fresh profile works, "Refresh Firefox" in `about:support` fixed it once. It leaves an `Old Firefox Data` folder on the desktop with your old passwords and cookies: keep it until you are sure, then delete it.
- **Upstream fixes.** Your list of candidate pull requests is kept outside the repository (`01-pr-ideas.md`).
