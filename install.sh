#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "==============================================="
echo "🚀 NixOS Workspace - Secure Installation"
echo "==============================================="
echo ""

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]
then
    echo "❌ Error: This script must be run with sudo."
    exit 1
fi

# 1. Detect target user (SUDO_USER contains the real username of the person who typed 'sudo')
DEFAULT_USER=${SUDO_USER:-"mainuser"}

read -p "👤 Enter your primary username [$DEFAULT_USER]: " INPUT_USER
TARGET_USER=${INPUT_USER:-$DEFAULT_USER}

# 2. System User Verification & Creation
if id "$TARGET_USER" &>/dev/null
then
    echo "✅ User '$TARGET_USER' already exists on the system."
else
    echo "⚠️ User '$TARGET_USER' does not exist!"
    read -p "Do you want to create it now and set a password? (Y/n): " CREATE_USER
    if [[ "$CREATE_USER" =~ ^[Nn]$ ]]
    then
        echo "❌ Aborted. The system user must exist to prevent permission lockouts."
        exit 1
    fi
    
    # Create the base user and prompt for password immediately
    useradd -m "$TARGET_USER"
    echo "🔑 Please set the password for $TARGET_USER:"
    passwd "$TARGET_USER"
fi

# 3. Patch configuration.nix safely
echo "🔧 Patching configuration.nix with user '$TARGET_USER'..."
# Replace the generic 'mainuser =' key with the actual username
sed -i "s/mainuser = {/$TARGET_USER = {/g" /etc/nixos/configuration.nix
sed -i "s/fullName = \"Main User\"/fullName = \"$TARGET_USER\"/g" /etc/nixos/configuration.nix

# 4. Build the System
echo "📦 Staging files for Nix..."
cd /etc/nixos
git config --global --add safe.directory /etc/nixos
git add .

echo "🔨 Building NixOS (this may take a few minutes)..."
nixos-rebuild switch

# 5. Fix permissions
echo "🔐 Assigning repository ownership to $TARGET_USER..."
chown -R "$TARGET_USER":users /etc/nixos
chown -R "$TARGET_USER":users "/home/$TARGET_USER"

echo ""
echo "🎉 System built successfully!"
echo "👉 Please close this terminal window and open a NEW one to initialize your workspace tools."
