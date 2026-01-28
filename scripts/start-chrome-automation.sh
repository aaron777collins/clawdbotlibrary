#!/bin/bash
# Chrome Automation Startup Script
# Starts Xvfb + Fluxbox + Chrome with proper daemonization
#
# Usage: $HOME/start-chrome-automation.sh
#
# GitHub: https://github.com/aaron777collins/clawdbotlibrary
# Docs:   docs/headless-browser-setup.md

# ============================================================
# Configuration - Adjust these if needed
# ============================================================
DISPLAY_NUM=":99"
DEBUG_PORT=9222
USER_DATA_DIR="$HOME/.chrome-automation"
LOG_DIR="/tmp"
EXTENSION_COORDS="1752 32"  # Fallback coordinates for extension icon

# Tool paths - will auto-detect if not set
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
ZOOMCLICK_PATH="${ZOOMCLICK_PATH:-$TOOLS_DIR/zoomclick/zoomclick.py}"
VCLICK_PATH="${VCLICK_PATH:-$TOOLS_DIR/vclick/vclick.py}"

# ============================================================
# Functions
# ============================================================
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
    
    # Check if already running (e.g., via systemd)
    if pgrep -f "Xvfb $DISPLAY_NUM" > /dev/null; then
        log "✓ Xvfb already running (PID: $(pgrep -f "Xvfb $DISPLAY_NUM"))"
        return 0
    fi
    
    setsid nohup Xvfb $DISPLAY_NUM -screen 0 1920x1080x24 > "$LOG_DIR/xvfb.log" 2>&1 &
    disown
    sleep 2
    
    if pgrep -f "Xvfb $DISPLAY_NUM" > /dev/null; then
        log "✓ Xvfb started (PID: $(pgrep -f "Xvfb $DISPLAY_NUM"))"
        return 0
    else
        log "✗ Xvfb failed to start!"
        return 1
    fi
}

start_fluxbox() {
    log "Starting Fluxbox window manager..."
    export DISPLAY=$DISPLAY_NUM
    
    # Check if already running
    if pgrep -x fluxbox > /dev/null; then
        log "✓ Fluxbox already running (PID: $(pgrep -x fluxbox))"
        return 0
    fi
    
    setsid nohup fluxbox > "$LOG_DIR/fluxbox.log" 2>&1 &
    disown
    sleep 2
    
    if pgrep -x fluxbox > /dev/null; then
        log "✓ Fluxbox started (PID: $(pgrep -x fluxbox))"
        return 0
    else
        log "✗ Fluxbox failed to start!"
        return 1
    fi
}

fix_chrome_prefs() {
    local PREFS_FILE="$USER_DATA_DIR/Default/Preferences"
    if [ -f "$PREFS_FILE" ]; then
        log "Fixing Chrome preferences (suppress crash dialog)..."
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
    print('  Done')
except Exception as e:
    print(f'  Warning: {e}')
" 2>/dev/null || true
    fi
}

start_chrome() {
    log "Starting Chrome with remote debugging on port $DEBUG_PORT..."
    export DISPLAY=$DISPLAY_NUM
    
    # Check if already running
    if pgrep -f "remote-debugging-port=$DEBUG_PORT" > /dev/null; then
        log "✓ Chrome already running (PID: $(pgrep -f "remote-debugging-port=$DEBUG_PORT" | head -1))"
        return 0
    fi
    
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
        log "✓ Chrome started (PID: $(pgrep -f "remote-debugging-port=$DEBUG_PORT" | head -1))"
        return 0
    else
        log "✗ Chrome failed to start!"
        return 1
    fi
}

click_extension() {
    log "Clicking Clawdbot extension icon..."
    export DISPLAY=$DISPLAY_NUM
    
    # Check if zoomclick is available
    if [ ! -f "$ZOOMCLICK_PATH" ]; then
        # Try system path
        if command -v zoomclick &> /dev/null; then
            ZOOMCLICK_PATH="zoomclick"
        else
            log "  zoomclick not found, using fallback coords"
            click_with_vclick
            return
        fi
    fi
    
    # Check if extension is already active (green "ON" badge)
    if [ -f "$HOME/.zoomclick/templates/clawdbot_extension_active.png" ]; then
        RESULT=$(python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension_active" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        if [ -n "$CONFIDENCE" ] && [ "$(echo "$CONFIDENCE > 0.8" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "✓ Extension already active (confidence: $CONFIDENCE)"
            return 0
        fi
    fi
    
    # Try zoomclick template for inactive state
    if [ -f "$HOME/.zoomclick/templates/clawdbot_extension.png" ]; then
        log "  Using zoomclick template..."
        RESULT=$(python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        
        if [ -n "$CONFIDENCE" ] && [ "$(echo "$CONFIDENCE > 0.7" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "  Template found (confidence: $CONFIDENCE), clicking..."
            python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension" 2>/dev/null
            log "✓ Extension clicked via template"
            return 0
        else
            log "  Template confidence too low ($CONFIDENCE)"
        fi
    fi
    
    # Fall back to direct coordinates
    click_with_vclick
}

click_with_vclick() {
    log "  Using fallback coords: $EXTENSION_COORDS"
    
    if [ -f "$VCLICK_PATH" ]; then
        python3 "$VCLICK_PATH" --coords $EXTENSION_COORDS 2>/dev/null || true
    elif command -v vclick &> /dev/null; then
        vclick --coords $EXTENSION_COORDS 2>/dev/null || true
    else
        log "  ⚠ Neither vclick nor coords available - extension may need manual click"
    fi
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
    log "⚠ DevTools not responding yet (Chrome may still be starting)"
    return 1
}

# ============================================================
# Main
# ============================================================
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
    log "Commands:"
    log "  Screenshot:  DISPLAY=$DISPLAY_NUM scrot /tmp/screenshot.png"
    log "  Zoomclick:   DISPLAY=$DISPLAY_NUM zoomclick --start"
    log "  DevTools:    curl -s http://localhost:$DEBUG_PORT/json/version"
    log ""
    log "Startup complete."
}

main "$@"
