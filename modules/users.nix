# Accounts of the machine. Each host declares them in hosts/<host>/users.nix;
# configuration.nix turns them into system users and per-user flakes.
{ lib, ... }:

{
  options.my.users = lib.mkOption {
    description = "Accounts of this machine and the layout each one gets.";
    default = { };
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        fullName = lib.mkOption { type = lib.types.str; };
        isAdmin = lib.mkOption { type = lib.types.bool; default = false; };
        layout = lib.mkOption { type = lib.types.str; default = "simple"; };
      };
    });
  };
}
