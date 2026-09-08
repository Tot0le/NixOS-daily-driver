# templates/minecraft-server-kit.nix
{ pkgs ? import <nixpkgs> {} }:

let
  # Default JDK — overwritten automatically by `setup-minecraft-server` (see
  # scripts/setup_minecraft_server.sh). JDK 21 covers most current loaders:
  # NeoForge 1.21.x, recent Fabric, Paper 1.20.5+.
  targetJava = pkgs.jdk21;

  # Custom derivation to fetch Playit directly since it's not in Nixpkgs yet
  playit = pkgs.stdenv.mkDerivation rec {
    pname = "playit";
    version = "1.0.10";
    src = pkgs.fetchurl {
      url = "https://github.com/playit-cloud/playit-agent/releases/download/v${version}/playit-linux-amd64";
      sha256 = "sha256-LffZ8QInqzErGtNBhT206KgkPfXPzbrlhxOkJxcRwzk=";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/playit
      chmod +x $out/bin/playit
    '';
  };

  customPython = pkgs.python3.withPackages (ps: with ps; [ discordpy ]);
in
pkgs.mkShell {
  buildInputs = [ targetJava playit pkgs.tmux customPython ];

  shellHook = ''
    echo "--- Minecraft Server Shell (${targetJava.pname}) ---"

    export JAVA_HOME="${targetJava.home}"

    echo "Info:"
    echo "  - Java: $(java -version 2>&1 | head -n 1)"
    echo ""
    echo "This shell provides Java, tmux, playit, and Python+discord.py."
    echo "See your launch script (start.sh) to run the server."
  '';
}
