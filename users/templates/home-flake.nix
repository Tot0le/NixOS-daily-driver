# Seeded once into ~/.config/home-manager/flake.nix by the system activation
# script, then owned by the user: it is never overwritten afterwards.
{
  description = "Home Manager configuration for @USERNAME@";

  inputs = {
    # Same nixpkgs revision as the system when the account was created, so that a
    # newer revision cannot break a package the system builds fine
    nixpkgs.url = "github:nixos/nixpkgs/@NIXPKGS_REV@";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Same nixpkgs everywhere, to avoid downloading a second copy
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Shared layouts and features: the local checkout, i.e. the code the
    # administrator maintains. Refresh with: nix flake update daily-driver
    daily-driver = {
      url = "path:/etc/nixos";
      # Used as a plain source tree, not as a flake
      flake = false;
    };
    serpantinum.url = "github:ilyamiro/serpantinum";
  };

  outputs = { nixpkgs, home-manager, daily-driver, serpantinum, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      homeConfigurations."@USERNAME@" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          serpantinum.homeManagerModules.default
          "${daily-driver}/users/layouts/@LAYOUT@.nix"
          {
            home.username = "@USERNAME@";
            home.homeDirectory = "/home/@USERNAME@";
            programs.home-manager.enable = true;
          }
          # Personal additions go below this line
        ];
      };
    };
}
