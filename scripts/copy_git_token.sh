#!/bin/bash

# Define secure local paths for token and access code.
declare secretFile="$HOME/.config/git-secret"
declare passFile="$HOME/.config/git-pass"

# Check for reset flag to replace credentials
if [ "$1" == "-r" ] || [ "$1" == "--reset" ]
then
    rm -f "$secretFile" "$passFile"
    echo "🧹 Existing credentials deleted. Forcing new setup..."
fi

# Initialize credentials via setup wizard if missing.
if [ ! -f "$secretFile" ] || [ ! -f "$passFile" ]
then
    echo "Initializing first-time setup..."
    
    declare inputToken=""
    read -s -p "Enter GitHub token: " inputToken
    echo ""
    
    declare inputPass=""
    read -s -p "Set local access code: " inputPass
    echo ""
    
    # Save credentials and enforce strict owner-only permissions.
    mkdir -p "$HOME/.config"
    echo -n "$inputToken" > "$secretFile"
    echo -n "$inputPass" > "$passFile"
    chmod 600 "$secretFile" "$passFile"
    
    echo "Setup completed successfully."
    exit 0
fi

# Prompt user for local access authorization.
declare userInput=""
read -s -p "Enter access code: " userInput
echo ""

declare expectedPass=""
expectedPass=$(cat "$passFile")

# Validate access code and dispatch token to clipboard.
if [[ "$userInput" == "$expectedPass" ]]
then
    cat "$secretFile" | wl-copy
    notify-send "GitHub" "Token copied securely." -i dialog-password
else
    echo "Access denied. Invalid code."
fi
