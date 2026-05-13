
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# TODO : steam, gérer compatibilité traduction programme windows en linux (epic games), feather client (minecraft)
# TODO : gérer les fichiers pour serveur minecraft
# TODO : gérer tout les autres fichiers personnels pour transférer les fichiers entre les deux OS

# /etc/nixos/configuration.nix
{ config, pkgs, ... }:

let
  # Define all system users and their respective roles
  # NOTE: After first rebuild, you must manually set passwords:
  # sudo passwd <username>
  # IMPORTANT: Run 'sudo chown -R <username>:users /etc/nixos' to fix shell permissions (e.g., Git status).
  usersConfigs = {
    anatole = { fullName = "Anatole"; isAdmin = true; layout = "all-Feature"; };
    user   = { fullName = "Random User";   isAdmin = false; layout = "simple"; };
  };
  
  # Extract names for module propagation
  userList = builtins.attrNames usersConfigs;
in
{
  imports = [ 
    ./hardware-configuration.nix

    # System-level modules (Hardware & Security)
    ./modules/cooling.nix
    ./modules/monitoring.nix
    ./modules/docker.nix
    #./modules/virtualization.nix
  ];

  # Global arguments for modules
  _module.args = { inherit userList usersConfigs; };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant. conflict with networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Generate user accounts with conditional admin rights
  users.users = pkgs.lib.mapAttrs (name: info: {
    isNormalUser = true;
    description = info.fullName;
    
    # Base groups for everyone
    # Add 'wheel' only if isAdmin is true
    extraGroups = [ "networkmanager" ] 
      ++ (if info.isAdmin then [ "wheel" ] else []);
  }) usersConfigs;


  # Generate standalone Home Manager templates for new users.
  system.activationScripts.setupUserHomes = ''
    ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (userName: userInfo: ''
      declare userHome="/home/${userName}"
      declare hmConfigDir="$userHome/.config/home-manager"
      declare hmConfigFile="$hmConfigDir/home.nix"

      if [ ! -f "$hmConfigFile" ]
      then
          ${pkgs.coreutils}/bin/mkdir -p "$hmConfigDir"
          
          # Copy layout and convert relative paths to absolute NixOS paths.
          ${pkgs.gnused}/bin/sed -e 's|\.\./\.\.|/etc/nixos|g' \
              -e 's|\./simple\.nix|/etc/nixos/users/layouts/simple.nix|g' \
              "/etc/nixos/users/layouts/${userInfo.layout}.nix" > "$hmConfigFile"
          
          # Remove final brace to append user-specific parameters.
          ${pkgs.gnused}/bin/sed -i '$ d' "$hmConfigFile"
          
          # Inject Home Manager identity and close configuration block.
          ${pkgs.coreutils}/bin/cat >> "$hmConfigFile" <<EOF
  home.username = "${userName}";
  home.homeDirectory = "$userHome";
  programs.home-manager.enable = true;
}
EOF
          
          # Assign ownership to target user.
          ${pkgs.coreutils}/bin/chown -R ${userName}:users "$userHome/.config"
      fi
    '') usersConfigs)}
  '';
  
  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Force Micro as the default editor system-wide (fixes sudo git commands)
  environment.variables = {
    EDITOR = "micro";
    VISUAL = "micro";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    # Basic tools
    gnome-text-editor
    pkgs.git
    pkgs.micro
    pkgs.btop
    
    # Programmation Languages
    python3

    # Some dependencies
    nbfc-linux
    wl-clipboard
    libnotify

  ];

  # Automate Home Manager installation on initial terminal session.
  environment.interactiveShellInit = ''
    if [ -f "$HOME/.config/home-manager/home.nix" ] && ! command -v home-manager &> /dev/null && [ -z "$HM_IS_INSTALLING" ]
    then
        export HM_IS_INSTALLING=1
        echo "🚀 Initializing personal workspace environment..."
        nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
        nix-channel --update
        
        if nix-shell '<home-manager>' -A install
        then
            echo ""
            echo "✅ Workspace ready. Tools and shortcuts deployed."
            echo "🔄 Please close and reopen this terminal to activate Zsh."
        else
            echo ""
            echo "❌ ERROR: Installation failed!"
            echo "Please fix the configuration errors above, then open a new terminal to try again."
        fi
    fi
  '';

  # Force micro to use system clipboard (wl-clipboard)
  environment.etc."micro/settings.json".text = ''
    {
        "clipboard": "external"
    }
  '';
  
  # Enable dconf to allow custom GNOME settings
  programs.dconf.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # web diagnostic & cybersecurity tools
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;


  # Open ports in the firewall.
  # Autorize the default minecraft ports 25565
  networking.firewall.allowedTCPPorts = [ 25565 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Automate garbage collection to prevent storage exhaustion
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Optimize storage by hardlinking identical files in the Nix store
  nix.settings.auto-optimise-store = true;
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
