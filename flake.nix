{
  description = "Personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;

      # One directory per machine under hosts/. Its name is the host name, so
      # `nixos-rebuild --flake /etc/nixos` selects the right configuration alone.
      hostNames = builtins.attrNames
        (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));
    in {
      nixosConfigurations = lib.genAttrs hostNames (host: lib.nixosSystem {
        system = "x86_64-linux";
        # Exposes `inputs` as an argument of every NixOS module
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/${host}
          { networking.hostName = host; }
        ];
      });
    };
}
