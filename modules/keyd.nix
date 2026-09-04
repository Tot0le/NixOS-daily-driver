# /etc/nixos/modules/keyd.nix
{ ... }:

{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(navigation, capslock)";
        };
        navigation = {
          left = "home";
          right = "end";
          up = "pageup";
          down = "pagedown";
        };
      };
    };
  };
}
