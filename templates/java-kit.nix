{ pkgs ? import <nixpkgs> {} }:

let
  # Use JDK 21 as the standard development base
  javaVersion = pkgs.jdk21;

  # Required system libraries for JavaFX native components and OpenGL hardware acceleration
  runtimeLibs = with pkgs; [
    libGL
    glib
    gtk3
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    xorg.libXxf86vm
    fontconfig
    freetype
  ];
in
pkgs.mkShell {
  buildInputs = [
    javaVersion
    pkgs.maven
  ] ++ runtimeLibs;

  shellHook = ''
    echo "--- Java & Maven Development Environment ---"
    
    # Export JAVA_HOME to ensure Maven and IDEs use the correct JDK path
    export JAVA_HOME="${javaVersion.home}"
    
    # Link native libraries to prevent UnsatisfiedLinkError during graphical execution
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"
    
    echo "Environment Info:"
    echo "  - JDK: ${javaVersion.version}"
    echo "  - Maven: $(mvn -v | head -n 1)"
    echo ""
    echo "🚀 IMPORTANT: To ensure Eclipse inherits this environment (Fixes libGL errors):"
    echo "   Type: eclipse &"
    echo ""
    echo "👉 To create a new project with JUnit 5 & JavaFX:"
    echo "mvn archetype:generate \\"
    echo "    -DarchetypeGroupId=org.openjfx \\"
    echo "    -DarchetypeArtifactId=javafx-archetype-simple \\"
    echo "    -DarchetypeVersion=0.0.6 \\"
    echo "    -DgroupId=com.dev.app \\"
    echo "    -DartifactId=projectName \\"
    echo "    -Dversion=1.0 \\"
    echo "    -DinteractiveMode=false"
    echo ""
    echo "💡 JUnit Tip: Add the following dependency to your pom.xml for testing:"
    echo "   <dependency>"
    echo "       <groupId>org.junit.jupiter</groupId>"
    echo "       <artifactId>junit-jupiter</artifactId>"
    echo "       <version>5.10.0</version>"
    echo "       <scope>test</scope>"
    echo "   </dependency>"
  '';
}
