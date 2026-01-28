#!/bin/bash
# Start Chrome on Xvfb display :99 with proper rendering
# See: ~/clawd/docs/chrome-xvfb-setup.md

DISPLAY_NUM=:99
USER_DATA_DIR=/home/ubuntu/.chrome-automation
DEBUG_PORT=9222

export DISPLAY=$DISPLAY_NUM

echo "Starting Chrome on $DISPLAY_NUM..."

# Kill existing processes
killall fluxbox chrome google-chrome 2>/dev/null
sleep 1

# Start window manager FIRST (critical!)
echo "Starting fluxbox..."
fluxbox 2>/dev/null &
sleep 2

# Verify fluxbox is running
if ! pgrep -x fluxbox > /dev/null; then
    echo "ERROR: Fluxbox failed to start!"
    exit 1
fi
echo "Fluxbox running (PID: $(pgrep -x fluxbox))"

# Start Chrome with required flags
echo "Starting Chrome..."
google-chrome \
    --user-data-dir="$USER_DATA_DIR" \
    --remote-debugging-port=$DEBUG_PORT \
    --no-first-run \
    --disable-gpu \
    --disable-software-rasterizer \
    --start-maximized \
    2>/dev/null &

sleep 5

# Verify Chrome is running
if ! pgrep -f "chrome.*$DEBUG_PORT" > /dev/null; then
    echo "ERROR: Chrome failed to start!"
    exit 1
fi

echo "Chrome running with DevTools on port $DEBUG_PORT"
echo ""
echo "Test screenshot: DISPLAY=$DISPLAY_NUM import -window root /tmp/test.png"
echo "Check DevTools:  curl -s http://localhost:$DEBUG_PORT/json | head"
