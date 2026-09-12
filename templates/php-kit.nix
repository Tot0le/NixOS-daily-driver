{ pkgs ? import <nixpkgs> {} }:

let
  # Configure PHP with database connection extensions
  myPhp = pkgs.php.buildEnv {
    extensions = ({ enabled, all }: enabled ++ (with all; [ 
      pdo_mysql
      mysqli
    ]));
  };
in
pkgs.mkShell {
  buildInputs = [
    myPhp
    pkgs.phpPackages.composer
    pkgs.mariadb
  ];

  shellHook = ''
    export MYSQL_DATADIR="$PWD/.mysql"
    export MYSQL_SOCKET="$PWD/mysql.sock"
    
    # Initialize the local database directory if it does not exist
    if [ ! -d "$MYSQL_DATADIR" ]
    then
      echo "⚙️ Initializing MariaDB database..."
      mariadb-install-db --auth-root-authentication-method=normal --datadir="$MYSQL_DATADIR" --basedir="${pkgs.mariadb}"
    fi

    # Start the MariaDB server in the background
    mariadbd --datadir="$MYSQL_DATADIR" --socket="$MYSQL_SOCKET" --port=3306 &
    MYSQL_PID=$!

    # Shortcut to start the PHP development server with an optional port
    serve() {
      local -i port
      if [ -z "$1" ]
      then
        port=8000
      else
        port=$1
      fi
      php -S "localhost:$port"
    }

    # Define help command
    help-env() {
      echo "🛠️  Available commands:"
      echo "  php -S localhost:8000  - Start development web server"
      echo "  serve [port]           - Shortcut to start web server (default: 8000)"
      echo "  mysql                  - Access the database via terminal"
      echo "  help-env               - Show this help message"
    }

    # Create alias for database access
    alias mysql="mariadb --socket=\"$MYSQL_SOCKET\" -u root"

    # Terminate the MariaDB process and wait for shutdown upon shell exit
    trap "echo '🛑 Stopping MariaDB...'; kill $MYSQL_PID; wait $MYSQL_PID 2>/dev/null" EXIT

    echo ""
    echo "🚀 Development environment ready!"
    echo ""
    help-env
    echo ""
    echo "🐘 For DBeaver: Connect to localhost (port 3306), user 'root', no password."
  '';
}
