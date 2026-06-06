{ pkgs ? import <nixpkgs> {} }:

let
  # Use JDK 21 as the standard development base
  jdkVersion = pkgs.jdk21;
in
(pkgs.buildFHSEnv {
  name = "java-media-dev-env";
  
  # Target packages to include in the simulated FHS environment
  targetPkgs = pkgs: with pkgs; [
    jdkVersion
    maven
    libGL
    gtk3
    glib
    xorg.libX11
    xorg.libXtst
    xorg.libXxf86vm
    xorg.libXi
    xorg.libXext
    xorg.libXrender
    fontconfig
    freetype
    alsa-lib
    libpulseaudio
    ffmpeg_4
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];
  
  # The profile script is executed upon entering the environment
  profile = ''
    echo "--- Java, Maven & JavaFX (FHS) Development Environment ---"
    
    # Export JAVA_HOME to ensure Maven and IDEs use the correct JDK path
    export JAVA_HOME="${jdkVersion.home}"
    
    echo "Environment Info:"
    echo "  - JDK: ${jdkVersion.version}"
    echo "  - Maven: \$(mvn -v | head -n 1)"
    echo ""
    echo "🚀 IMPORTANT: You are now in a simulated standard Linux environment."
    echo "   Type: eclipse &"
    echo "   (This ensures Eclipse and Maven plugins find native libraries correctly)"
  '';
  
  runScript = "bash";
}).env
