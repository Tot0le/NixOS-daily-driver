#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Graceful shutdown: ask every client window to close and give it time to
# save its state (Firefox session/cookies, editors, etc.) before tearing
# down the session. Avoids corrupting app data via a hard SIGKILL.
# -----------------------------------------------------------------------------

MAX_WAIT=5      # seconds to wait for apps to close themselves
POLL_INTERVAL=0.2

# Ask every open window to close (equivalent to clicking the X / Ctrl+Q)
hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
    hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1
done

# Wait until all windows are actually gone, or MAX_WAIT is reached
elapsed=0
while (( $(echo "$elapsed < $MAX_WAIT" | bc -l) )); do
    remaining=$(hyprctl clients -j | jq 'length')
    [ "$remaining" -eq 0 ] && break
    sleep "$POLL_INTERVAL"
    elapsed=$(echo "$elapsed + $POLL_INTERVAL" | bc -l)
done

systemctl --user stop graphical-session.target
systemctl --user stop graphical-session-pre.target

sleep 0.5

hyprctl dispatch exit
