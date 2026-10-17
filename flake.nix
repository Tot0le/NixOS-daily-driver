{
  description = "Personal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    serpantinum.url = "github:ilyamiro/serpantinum";
  };

  # "@inputs" names the whole set of inputs so we can forward it below
  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Exposes `inputs` as an argument of every NixOS module
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # System services the shell expects (NetworkManager, i2c, PipeWire).
        # The per-user side lives in each user's own Home Manager flake.
        inputs.serpantinum.nixosModules.default
      ];
    };
  };
}
