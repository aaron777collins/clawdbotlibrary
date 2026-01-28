#!/bin/bash
# Chrome Automation Startup Script (Robust Version)
# Starts Xvfb + Fluxbox + Chrome with proper daemonization
# Docs: ~/clawd/docs/chrome-automation-setup.md

DISPLAY_NUM=":99"
DEBUG_PORT=9222
USER_DATA_DIR="/home/ubuntu/.chrome-automation"
LOG_DIR="/tmp"
EXTENSION_COORDS="1752 32"  # Clawdbot extension icon location (fallback coordinates)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

cleanup() {
    log "Cleaning up existing processes..."
    pkill -f "Xvfb $DISPLAY_NUM" 2>/dev/null || true
    pkill -f "fluxbox" 2>/dev/null || true
    pkill -f "remote-debugging-port=$DEBUG_PORT" 2>/dev/null || true
    sleep 2
}

start_xvfb() {
    log "Starting Xvfb on display $DISPLAY_NUM..."
    setsid nohup Xvfb $DISPLAY_NUM -screen 0 1920x1080x24 > "$LOG_DIR/xvfb.log" 2>&1 &
    disown
    sleep 2
    
    if pgrep -f "Xvfb $DISPLAY_NUM" > /dev/null; then
        log "✓ Xvfb running (PID: $(pgrep -f "Xvfb $DISPLAY_NUM"))"
        return 0
    else
        log "✗ Xvfb failed to start!"
        return 1
    fi
}

start_fluxbox() {
    log "Starting Fluxbox window manager..."
    export DISPLAY=$DISPLAY_NUM
    setsid nohup fluxbox > "$LOG_DIR/fluxbox.log" 2>&1 &
    disown
    sleep 2
    
    if pgrep -x fluxbox > /dev/null; then
        log "✓ Fluxbox running (PID: $(pgrep -x fluxbox))"
        return 0
    else
        log "✗ Fluxbox failed to start!"
        return 1
    fi
}

fix_chrome_prefs() {
    local PREFS_FILE="$USER_DATA_DIR/Default/Preferences"
    if [ -f "$PREFS_FILE" ]; then
        log "Fixing Chrome preferences..."
        python3 -c "
import json
try:
    with open('$PREFS_FILE', 'r') as f:
        prefs = json.load(f)
    if 'profile' not in prefs:
        prefs['profile'] = {}
    prefs['profile']['exit_type'] = 'Normal'
    prefs['profile']['exited_cleanly'] = True
    with open('$PREFS_FILE', 'w') as f:
        json.dump(prefs, f)
    print('Done')
except Exception as e:
    print(f'Warning: {e}')
" 2>/dev/null || true
    fi
}

start_chrome() {
    log "Starting Chrome with remote debugging on port $DEBUG_PORT..."
    export DISPLAY=$DISPLAY_NUM
    
    setsid nohup google-chrome \
        --remote-debugging-port=$DEBUG_PORT \
        --user-data-dir="$USER_DATA_DIR" \
        --no-first-run \
        --no-default-browser-check \
        --disable-blink-features=AutomationControlled \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --hide-crash-restore-bubble \
        --disable-gpu \
        --disable-dev-shm-usage \
        --no-sandbox \
        --window-size=1920,1080 \
        --start-maximized \
        "about:blank" > "$LOG_DIR/chrome.log" 2>&1 &
    disown
    sleep 4
    
    if pgrep -f "remote-debugging-port=$DEBUG_PORT" > /dev/null; then
        log "✓ Chrome running (PID: $(pgrep -f "remote-debugging-port=$DEBUG_PORT" | head -1))"
        return 0
    else
        log "✗ Chrome failed to start!"
        return 1
    fi
}

click_extension() {
    log "Clicking Clawdbot extension icon..."
    export DISPLAY=$DISPLAY_NUM
    
    # Check if extension is already active by looking for "ON" state
    if [ -f ~/.zoomclick/templates/clawdbot_extension_active.png ]; then
        cd ~/clawd/tools/zoomclick
        RESULT=$(python3 zoomclick.py --click "clawdbot_extension_active" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        if [ "$(echo "$CONFIDENCE > 0.8" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "✓ Extension already active (detected ON state with confidence $CONFIDENCE)"
            return 0
        fi
    fi
    
    # Try zoomclick template first (for inactive state)
    if [ -f ~/.zoomclick/templates/clawdbot_extension.png ]; then
        log "Using zoomclick template for extension click"
        cd ~/clawd/tools/zoomclick
        RESULT=$(python3 zoomclick.py --click "clawdbot_extension" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        
        # Only use template match if confidence is high enough
        if [ "$(echo "$CONFIDENCE > 0.7" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "Template found with confidence $CONFIDENCE, clicking..."
            python3 zoomclick.py --click "clawdbot_extension" 2>/dev/null
            log "✓ Extension clicked via template matching"
            return 0
        else
            log "Template confidence too low ($CONFIDENCE), using fallback coords"
        fi
    fi
    
    # Fall back to vclick with hardcoded coordinates
    log "Falling back to vclick coordinates ($EXTENSION_COORDS)"
    python3 ~/clawd/tools/vclick/vclick.py --coords $EXTENSION_COORDS 2>/dev/null || true
    sleep 1
}

verify_devtools() {
    log "Verifying DevTools endpoint..."
    for i in {1..5}; do
        if curl -s http://localhost:$DEBUG_PORT/json/version > /dev/null 2>&1; then
            log "✓ DevTools responding on port $DEBUG_PORT"
            return 0
        fi
        sleep 1
    done
    log "⚠ DevTools not responding (Chrome may still be starting)"
    return 1
}

main() {
    log "=========================================="
    log "Chrome Automation Startup"
    log "=========================================="
    
    cleanup
    
    start_xvfb || exit 1
    start_fluxbox || exit 1
    fix_chrome_prefs
    start_chrome || exit 1
    verify_devtools
    
    # Give Chrome time to fully load before clicking extension
    sleep 3
    click_extension
    
    log ""
    log "=========================================="
    log "✓ Chrome automation ready!"
    log "  Display: $DISPLAY_NUM"
    log "  Debug port: $DEBUG_PORT"
    log "  User data: $USER_DATA_DIR"
    log "=========================================="
    log ""
    log "Screenshot: DISPLAY=$DISPLAY_NUM scrot /tmp/screenshot.png"
    log "Zoomclick:  DISPLAY=$DISPLAY_NUM zoomclick --start"
    log "Browser:    browser action=screenshot profile=sophie"
    log ""
    log "Startup complete."
}

main "$@"
