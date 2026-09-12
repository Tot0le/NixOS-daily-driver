#!/bin/bash

declare -r templatePath="/etc/nixos/templates/php-kit.nix"

# Copy template if missing
if [ ! -f "shell.nix" ]
then
    cp "$templatePath" ./shell.nix
    echo "Php template copied to current directory."
fi

# Open editor for manual adjustments
nano shell.nix

# Initialize isolated environment
nix-shell
