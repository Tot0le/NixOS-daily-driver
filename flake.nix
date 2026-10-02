{
  description = "Personal NixOS configuration";

  inputs = {
    # Same release as the running system (26.05), to avoid an accidental upgrade
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Shell theme maintained upstream; tracked here, not copied
    serpantinum.url = "github:ilyamiro/serpantinum";
  };

  outputs = { self, nixpkgs, ... }: {
    # Must match networking.hostName
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
