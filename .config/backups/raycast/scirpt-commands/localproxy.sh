#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title LocalProxy
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Network Utils Shadowrocket

# Documentation:
# @raycast.description Listenning 2082 port, redirect incomming traffics to Shadowrockets TUN Port.
# @raycast.author awenoo1
# @raycast.authorURL https://raycast.com/awenoo1

PID_FILE="/var/tmp/localproxy"

if [[ -f "$PID_FILE" ]]; then
  EXISTING_PID="$(cat "$PID_FILE" 2>/dev/null)"
  if [[ "$EXISTING_PID" =~ ^[0-9]+$ ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
    kill -9 "$EXISTING_PID"
    echo "Stopped existing localproxy process (PID: $EXISTING_PID)"
    rm -f "$PID_FILE"
    exit 0
  fi
fi

nohup /opt/homebrew/bin/socat TCP4-LISTEN:2082,fork,reuseaddr TCP4:198.18.0.3:1082 &
NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"
echo "Started localproxy process (PID: $NEW_PID)"
