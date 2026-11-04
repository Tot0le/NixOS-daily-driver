#!/usr/bin/env bash
# First installation on a machine that already runs a fresh NixOS.
# Creates hosts/<machine>/ from what the NixOS installer decided for this
# machine (hardware, boot loader, release), declares the first account, then
# builds it and makes it the default at the next boot. The repository must be
# cloned in /etc/nixos.

set -euo pipefail

readonly REPO="/etc/nixos"
# The installer's own configuration, moved aside before cloning (see the README)
readonly ORIGINAL="/etc/nixos.orig"

die() {
    echo "❌ $*" >&2
    exit 1
}

[ "$EUID" -eq 0 ] || die "This script must be run with sudo."
[ "$(readlink -f "$(dirname "$0")")" = "$REPO" ] || die "Run this script from the repository cloned in $REPO."
cd "$REPO"
[ -f flake.nix ] && [ -d hosts ] || die "$REPO does not look like this repository."

echo "==============================================="
echo "🚀 NixOS daily driver - first installation"
echo "==============================================="
echo ""

# --- Questions ---------------------------------------------------------------

declare defaultUser="${SUDO_USER:-}"
declare inputUser=""
read -r -p "👤 Primary username [$defaultUser]: " inputUser
declare targetUser="${inputUser:-$defaultUser}"
[[ "$targetUser" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username '$targetUser': use lowercase letters, digits, '-' and '_'."

declare inputFullName=""
read -r -p "📛 Full name [$targetUser]: " inputFullName
declare fullName="${inputFullName:-$targetUser}"
# The name is written inside a Nix string: refuse what could break out of it
case "$fullName" in
    *\"* | *\\* | *\$* | *\`*) die "The full name cannot contain \", \\, \$ or backticks." ;;
esac

declare -a layouts
mapfile -t layouts < <(find users/layouts -maxdepth 1 -name '*.nix' -printf '%f\n' | sed 's/\.nix$//' | sort)
declare inputLayout=""
read -r -p "🎨 Layout (${layouts[*]}) [all-Feature]: " inputLayout
declare layout="${inputLayout:-all-Feature}"
printf '%s\n' "${layouts[@]}" | grep -qx -- "$layout" || die "Unknown layout '$layout'."

# The machine name is also the directory name under hosts/ and the host name
declare defaultHost="${targetUser//_/-}-pc"
declare inputHost=""
read -r -p "🖥️  Machine name [$defaultHost]: " inputHost
declare host="${inputHost:-$defaultHost}"
[[ "$host" =~ ^[a-z]([a-z0-9-]*[a-z0-9])?$ ]] || die "Invalid machine name '$host': lowercase letters, digits and '-', starting with a letter."
[ ! -e "hosts/$host" ] || die "hosts/$host already exists: pick another machine name."

# --- What the NixOS installer decided for this machine ------------------------

declare stateVersion=""
declare bootLines=""
if [ -f "$ORIGINAL/configuration.nix" ]
then
    stateVersion="$(grep -oE 'system\.stateVersion = "[^"]+"' "$ORIGINAL/configuration.nix" | grep -oE '"[^"]+"' | tr -d '"' | head -n 1 || true)"
    # Single-line, uncommented boot.loader settings are copied as they are
    bootLines="$(grep -E '^[[:space:]]*boot\.loader\.[^#]*;' "$ORIGINAL/configuration.nix" || true)"
    echo "✅ Read from $ORIGINAL/configuration.nix: release '$stateVersion' and these boot loader settings:"
    echo "$bootLines"
fi

if [ -z "$stateVersion" ]
then
    stateVersion="$(nixos-version | cut -d. -f1,2)"
    echo "ℹ️  No installer configuration to read the first-install release from: using the current release ($stateVersion)."
fi

if [ -z "$bootLines" ]
then
    [ -d /sys/firmware/efi ] || die "Could not read the boot loader settings and this machine does not boot in UEFI mode. Put the installer's configuration back as $ORIGINAL (see the README) and run this script again."
    bootLines='  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;'
    echo "ℹ️  Boot loader settings not found: using systemd-boot (UEFI)."
fi

# --- Warnings -------------------------------------------------------------------

# The flake is built on the nixpkgs release it declares: an older installer image
# means an upgrade
declare configRelease=""
configRelease="$(grep -oE 'nixpkgs/nixos-[0-9]+\.[0-9]+' flake.nix | head -n 1 | sed 's|.*nixos-||' || true)"
declare runningRelease=""
runningRelease="$(nixos-version | cut -d. -f1,2)"
if [ -n "$configRelease" ] && [ "$configRelease" != "$runningRelease" ]
then
    echo "ℹ️  This system runs NixOS $runningRelease and the configuration is built on $configRelease:"
    echo "   that is an upgrade. An installer image of release $configRelease avoids it."
fi

# Accounts that the new configuration does not declare are normally removed
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "$targetUser" ]
then
    echo "⚠️  You are logged in as '$SUDO_USER', which the new configuration does not declare:"
    echo "   NixOS normally removes such accounts (their files in /home stay)."
    echo "   Use '$SUDO_USER' as primary username to keep it."
    declare confirm=""
    read -r -p "Continue anyway? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || die "Aborted."
fi

# --- Generate hosts/<machine>/ ------------------------------------------------

declare staging=""
staging="$(mktemp -d "$REPO/hosts/.new.XXXXXX")"
# Never leave a half-written directory behind: the flake would list it as a machine
trap 'rm -rf "$staging"' EXIT

nixos-generate-config --show-hardware-config > "$staging/hardware-configuration.nix"

cat > "$staging/users.nix" <<EOF
{
  my.users = {
    $targetUser = { fullName = "$fullName"; isAdmin = true; layout = "$layout"; };
  };
}
EOF

cat > "$staging/default.nix" <<EOF
# Generated by install.sh. Anything specific to this machine lives here; what
# every machine shares is in configuration.nix and modules/.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./users.nix
  ];

  # Boot loader, as chosen by the NixOS installer for this machine
$bootLines

  # Release this machine was first installed with: never change it
  system.stateVersion = "$stateVersion";
}
EOF

chmod 755 "$staging"
mv "$staging" "hosts/$host"
echo "✅ Created hosts/$host"

# --- System account -----------------------------------------------------------

if id "$targetUser" &> /dev/null
then
    echo "✅ User '$targetUser' already exists on the system."
else
    useradd -m "$targetUser"
    echo "🔑 Set the password for $targetUser:"
    passwd "$targetUser"
fi

# --- Build for the next boot ----------------------------------------------------

# root runs git on a repository it may not own, and a flake only sees tracked files
git config --global --add safe.directory "$REPO"
git add "hosts/$host"

# 'boot' and not 'switch': in testing, switching live restarted the desktop session
# of the person installing, left a black screen and killed the terminal running this
# script. The new system is simply the one that starts next.
echo "🔨 Building '$host' for the next boot (this can take a long time)."
echo "   If it fails, fix the cause and run: sudo nixos-rebuild boot --flake $REPO#$host"
nixos-rebuild boot --flake "$REPO#$host"

echo ""
echo "🎉 Installed. The new system starts at the next boot. Your personal environment"
echo "   is set up when you open your first terminal there (a few minutes, needs the network)."

declare answer=""
read -r -p "Reboot now? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]
then
    systemctl reboot
fi
