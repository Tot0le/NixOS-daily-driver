# users/features/curseforge.nix
{ config, pkgs, ... }:

let
  pname = "curseforge";
  version = "latest";

  src = pkgs.fetchurl {
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.AppImage";
    sha256 = "13vd0jsib52lgzgi4h9mk8kl0ij93hd37r9z3dq19pgmqly2knch";
  };

  curseforgeNative = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
  };
in
{
  home.packages = [
    curseforgeNative
  ];

  xdg.desktopEntries.curseforge = {
    name = "CurseForge";
    exec = "${curseforgeNative}/bin/curseforge %u";
    terminal = false;
    type = "Application";
    mimeType = [ "x-scheme-handler/curseforge" ];
  };
}
