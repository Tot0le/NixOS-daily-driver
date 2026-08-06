# /etc/nixos/users/layouts/all-Feature.nix
{ config, pkgs, lib, ... }:

let
  # Centralized shortcut catalog.
  shortcutCatalog = import ../../conf/shortcuts.list.nix;

  # Package pure bash scripts into executables dynamically
  pickColorScript = pkgs.writeShellScriptBin "pick_color.sh" (builtins.readFile ../../scripts/pick_color.sh);
  copyGitToken = pkgs.writeShellScriptBin "copyGitToken" (builtins.readFile ../../scripts/copy_git_token.sh);

  # Environment setup scripts
  setupDb = pkgs.writeShellScriptBin "setup-db" (builtins.readFile ../../scripts/setup_db.sh);
  setupJava = pkgs.writeShellScriptBin "setup-java" (builtins.readFile ../../scripts/setup_java.sh);
  setupMinecraft = pkgs.writeShellScriptBin "setup-minecraft" (builtins.readFile ../../scripts/setup_minecraft.sh);

in
{
  # Inherit base configuration from simple.nix.
  imports = [
    ./simple.nix
    ../../users/features/kathara.nix
    ../../users/features/gnome-custom.nix
    ../../users/features/kitty-terminal.nix 
    ../../users/features/zsh-shell.nix
    ../../users/features/hyprland-custom.nix
  ];

  # User-specific GNOME settings
  my.gnome.desktopIcons = true;
  my.gnome.taskbar = true;
  my.gnome.wallpaper = "${config.home.homeDirectory}/Pictures/default_wallpaper.jpg";

  # Force override the JSON file with the comprehensive shortcut list.
  xdg.configFile."shortcuts-base.json".text = lib.mkForce (builtins.toJSON (
    shortcutCatalog.commonApps // 
    shortcutCatalog.adminApps // 
    shortcutCatalog.terminalTools // # (kitty)
    shortcutCatalog.graphicTools // 
    shortcutCatalog.fans
  ));

  # Allow unfree packages specifically for Home Manager sessions
  nixpkgs.config.allowUnfree = true;

  # Declarative Git configuration
  programs.git = {
    enable = true;
    settings = {
      core.editor = "micro";
    };
  };

  # Set Micro as the default editor for the shell session
  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    GIT_ASKPASS = "";
    SSH_ASKPASS = "";
  };

  
  home.packages = [
    # Kitty terminal
    pkgs.kitty

    # A git tool
    pkgs.gitkraken

    # Text editor
    pkgs.vscode

    # Productivity apps
    pkgs.obsidian
    pkgs.pinta
    
    # Java Development Base
    pkgs.jdk21
    pkgs.eclipses.eclipse-java
    pkgs.scenebuilder

    # Java plugins
    pkgs.plantuml
    pkgs.graphviz
    pkgs.sonar-scanner-cli
    
    # Environment Setups
    setupDb
    setupJava
    setupMinecraft
    
    # Add private token script.
    copyGitToken

    # Direct import of pick_color script bypassing global modules.
    pickColorScript
  ];
  
}
