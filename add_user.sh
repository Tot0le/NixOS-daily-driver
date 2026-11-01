#!/usr/bin/env bash
# Adds an account to this machine: creates the system user, declares it in
# hosts/<machine>/users.nix, then rebuilds. Run it with sudo.

set -euo pipefail

readonly REPO="/etc/nixos"

die() {
    echo "❌ $*" >&2
    exit 1
}

[ "$EUID" -eq 0 ] || die "This script must be run with sudo."
cd "$REPO"

# The directory under hosts/ is named after the machine
declare host=""
host="$(hostname)"
declare usersFile="hosts/$host/users.nix"
[ -f "$usersFile" ] || die "No $REPO/$usersFile: this machine ('$host') has no configuration here. Run install.sh first."

echo "==============================================="
echo "👤 NixOS - Add New User"
echo "==============================================="
echo ""

declare inputUser=""
read -r -p "Enter new username (e.g., alice): " inputUser
[[ "$inputUser" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username '$inputUser': use lowercase letters, digits, '-' and '_'."
if grep -qE "^[[:space:]]+$inputUser = " "$usersFile"
then
    die "'$inputUser' is already declared in $usersFile."
fi

declare inputFullName=""
read -r -p "Enter full name (e.g., Alice Smith) [$inputUser]: " inputFullName
declare fullName="${inputFullName:-$inputUser}"
# The name is written inside a Nix string: refuse what could break out of it
case "$fullName" in
    *\"* | *\\* | *\$* | *\`*) die "The full name cannot contain \", \\, \$ or backticks." ;;
esac

declare inputAdmin=""
read -r -p "Is this user an admin? (y/N): " inputAdmin
declare isAdmin="false"
if [[ "$inputAdmin" =~ ^[Yy]$ ]]
then
    isAdmin="true"
fi

declare -a layouts
mapfile -t layouts < <(find users/layouts -maxdepth 1 -name '*.nix' -printf '%f\n' | sed 's/\.nix$//' | sort)
declare inputLayout=""
read -r -p "Which layout? (${layouts[*]}) [simple]: " inputLayout
declare layout="${inputLayout:-simple}"
printf '%s\n' "${layouts[@]}" | grep -qx -- "$layout" || die "Unknown layout '$layout'."

# 1. Create the system user and its password
if id "$inputUser" &> /dev/null
then
    echo "⚠️  User '$inputUser' already exists on the system: skipping its creation."
else
    useradd -m "$inputUser"
    echo "🔑 Please set the password for $inputUser:"
    passwd "$inputUser"
fi

# 2. Declare the account in this machine's users file
echo "🔧 Adding $inputUser to $usersFile..."
declare newLine="    $inputUser = { fullName = \"$fullName\"; isAdmin = $isAdmin; layout = \"$layout\"; };"
declare tmpFile=""
tmpFile="$(mktemp)"
trap 'rm -f "$tmpFile"' EXIT
# The line goes right after the opening of the my.users set
awk -v new="$newLine" '{ print } /^  my\.users = \{$/ { print new }' "$usersFile" > "$tmpFile"
grep -qF -- "$newLine" "$tmpFile" || die "Could not add the account: $usersFile has no '  my.users = {' line."
cat "$tmpFile" > "$usersFile"

# 3. Build and activate
# root runs git on a repository it may not own, and a flake only sees tracked files
git config --global --add safe.directory "$REPO"
git add "$usersFile"
echo "🔨 Rebuilding NixOS..."
nixos-rebuild switch --flake "$REPO#$host"

# The activation creates the account's flake as root: make sure the home is theirs
chown -R "$inputUser":users "/home/$inputUser"

echo ""
echo "🎉 User $inputUser added successfully!"
echo ""
echo "👉 To change this user's layout or admin rights later, edit $REPO/$usersFile"
echo "   and rebuild with: sudo nixos-rebuild switch --flake $REPO#$host"
