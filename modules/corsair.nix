# /etc/nixos/modules/corsair.nix
{ pkgs, ... }:

{
  # Enable the ckb-next daemon and GUI for Corsair devices
  hardware.ckb-next.enable = true;
}
