#!/bin/bash

declare -r templatePath="/etc/nixos/templates/minecraft-server-kit.nix"

# Minecraft version -> matching JDK
declare -a options=(
    "NeoForge 1.21.1 / recent Fabric, Paper (1.20.5+)|21"
    "Paper Experimental / latest builds (2026+)|25"
    "Minecraft 1.18 to 1.20.4|17"
    "Minecraft 1.8 to 1.16|8"
)

if [ ! -f "shell.nix" ]; then
    echo "Which server version do you want to host?"
    select choice in "${options[@]%|*}" "Other (enter JDK number manually)"; do
        if [ -n "$choice" ]; then
            if [ "$REPLY" -le "${#options[@]}" ]; then
                javaVersion="${options[$((REPLY-1))]#*|}"
            else
                read -rp "Nix JDK number (e.g. 21): " javaVersion
            fi
            break
        fi
        echo "Invalid choice."
    done

    cp "$templatePath" ./shell.nix
    sed -i \
        -e "s/targetJava = pkgs\.jdk[0-9]*/targetJava = pkgs.jdk${javaVersion}/" \
        -e "s/# Using JDK .*/# Using JDK ${javaVersion} (selected via setup-minecraft-server)/" \
        ./shell.nix

    # Also drop in the generic server launcher, if not already present
    if [ ! -f "start.sh" ]; then
        cp "/etc/nixos/templates/minecraft-server-start.sh" ./start.sh
        chmod +x ./start.sh
        echo "Launcher script copied (start.sh)."
    fi

    echo "Minecraft template copied (JDK ${javaVersion})."
fi

nano shell.nix
nix-shell
