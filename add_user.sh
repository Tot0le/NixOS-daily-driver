#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "==============================================="
echo "👤 NixOS - Add New User"
echo "==============================================="
echo ""

if [ "$EUID" -ne 0 ]
then
    echo "❌ Error: This script must be run with sudo."
    exit 1
fi

declare inputUser=""
read -p "Enter new username (e.g., alice): " inputUser

declare inputFullName=""
read -p "Enter full name (e.g., Alice Smith): " inputFullName

declare inputAdmin=""
read -p "Is this user an admin? (y/N): " inputAdmin

declare inputLayout=""
read -p "Which layout? (all-Feature/simple) [simple]: " inputLayout

# Format variables safely
declare isAdmin="false"
if [[ "$inputAdmin" =~ ^[Yy]$ ]]
then
    isAdmin="true"
fi

declare targetLayout="simple"
if [ "$inputLayout" == "all-Feature" ]
then
    targetLayout="all-Feature"
fi

# 1. Create Linux user and password
if id "$inputUser" &>/dev/null
then
    echo "⚠️ User '$inputUser' already exists on the Linux system. Skipping system creation."
else
    useradd -m "$inputUser"
    echo "🔑 Please set the password for $inputUser:"
    passwd "$inputUser"
fi

# 2. Inject into configuration.nix dynamically
echo "🔧 Adding $inputUser to NixOS configuration..."
declare newLine="    $inputUser = { fullName = \"$inputFullName\"; isAdmin = $isAdmin; layout = \"$targetLayout\"; };"

# Append the new line right after the opening bracket of usersConfigs
sed -i "/usersConfigs = {/a \\$newLine" /etc/nixos/configuration.nix

# 3. Build System
echo "🔨 Rebuilding NixOS..."
nixos-rebuild switch

# Fix permissions to prevent GNOME login loop
chown -R "$inputUser":users "/home/$inputUser"

echo "🎉 User $inputUser added successfully!"
echo ""
echo "👉 Note: To manually modify this user's settings later (layout, admin rights),"
echo "   simply edit the 'usersConfigs' section in /etc/nixos/configuration.nix"
