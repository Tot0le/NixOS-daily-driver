{ pkgs ? import <nixpkgs> {} }:

let
  # Default JDK — overwritten automatically by `setup-minecraft` (see 
  # scripts/setup_minecraft.sh). JDK 21 covers most current loaders:
  # NeoForge 1.21.x, recent Fabric, Paper 1.20.5+.
  targetJava = pkgs.jdk21;

  # Custom derivation to fetch Playit directly since it's not in Nixpkgs yet
  playit = pkgs.stdenv.mkDerivation rec {
    pname = "playit";
    version = "0.17.1";
    src = pkgs.fetchurl {
      url = "https://github.com/playit-cloud/playit-agent/releases/download/v${version}/playit-linux-amd64";
      sha256 = "sha256-541GPZOqHj7Dagbe1aH0/oeZBf3OuGXfj0zvYST4pVU="; 
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/playit
      chmod +x $out/bin/playit
    '';
  };

  # Required for Kitty to launch without OpenGL errors
  runtimeLibs = with pkgs; [
    libGL
    xorg.libX11
  ];
in
pkgs.mkShell {
  buildInputs = [
    targetJava
    playit
  ] ++ runtimeLibs;

  shellHook = ''
    echo "--- Minecraft & Playit Environment (${targetJava.pname}) ---"
    
    export JAVA_HOME="${targetJava.home}"
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"
    
    echo "Info:"
    echo "  - Java: $(java -version 2>&1 | head -n 1)"
    echo "  - Playit: Installed locally via fetchurl"
    echo ""
    echo "🚀 To start your server, run: bash start.sh"
  '';
}
