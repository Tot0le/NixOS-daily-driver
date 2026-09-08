#!/usr/bin/env bash

# ============================================================
#  start.sh — Server launcher (tmux + Playit)
#
#  Usage : ./start.sh
#
#  Launches the server automatically in a tmux session "mc":
#    - Window 0 ("minecraft") : interactive server console
#    - Window 1 ("playit")    : active Playit tunnel
#
#  Switch between windows:
#    - Go to Playit    : Ctrl+B then 1 (or n)
#    - Back to Minecraft : Ctrl+B then 0 (or p)
#
#  Detach without stopping : Ctrl+B then D
#  Reattach                : tmux attach -t mc
# ============================================================

SESSION="mc"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNING_MARKER="$SCRIPT_DIR/.server_running"
PLAYIT_BIN="playit --socket-path /tmp/playit.sock"

function closeServer() {
    rm -f "$RUNNING_MARKER"
}

trap closeServer EXIT SIGINT SIGTERM

# If already INSIDE the "mc" tmux session, run the server loop
if [[ "$TMUX_SESSION_NAME" == "$SESSION" || "$TMUX" == *"$SESSION"* ]]
then
    while true
    do
        echo "--- Starting the server ---"
        touch "$RUNNING_MARKER"
        cd "$SCRIPT_DIR" && systemd-inhibit --what=idle:sleep:handle-lid-switch --who="Minecraft" --why="Server active" ./run.sh nogui
        rm -f "$RUNNING_MARKER"
        echo "Server stopped or crashed."

        # If sleep_mode.sh requested a stop, don't restart
        if [[ -f "$SCRIPT_DIR/.sleep_stop" ]]
        then
            rm -f "$SCRIPT_DIR/.sleep_stop"
            echo "Stop requested by sleep mode — not restarting."
            break
        fi

        # If the Discord bot requested a restart (!restart), restart right away
        if [[ -f "$SCRIPT_DIR/.auto_restart" ]]
        then
            rm -f "$SCRIPT_DIR/.auto_restart"
            echo "🔄 Automatic restart requested via Discord — restarting now."
            continue
        fi

        read -t 10 -p "Restart the server? (Y/n) (Auto-restart in 10s): " restartChoice
        if [[ "$restartChoice" == "n" || "$restartChoice" == "N" ]]
        then
            echo "Stopping for good."
            break
        fi
        echo "Restarting..."
    done
    tmux kill-session -t "$SESSION" 2>/dev/null
    exit 0
fi

# Kill any leftover "mc" session
tmux kill-session -t "$SESSION" 2>/dev/null

# Create the tmux session with the server console (background with -d)
tmux new-session -d -s "$SESSION" -n "minecraft" -e "TMUX_SESSION_NAME=$SESSION" "cd '$SCRIPT_DIR' && bash '$0'"

# Open the second window for Playit
tmux new-window -t "$SESSION:1" -n "playit" "cd '$SCRIPT_DIR' && $PLAYIT_BIN"

# Go back to the Minecraft window and attach
tmux select-window -t "$SESSION:0"
tmux attach-session -t "$SESSION"

echo "Session ended."
