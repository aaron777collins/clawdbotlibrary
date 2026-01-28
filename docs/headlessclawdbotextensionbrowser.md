# Headless Clawdbot Browser Extension Setup

> **Complete guide to running Chrome headlessly with Clawdbot Browser Relay on a fresh Ubuntu server.**
> 
> This guide is self-contained. Follow it step-by-step on a fresh server and you'll have a working headless browser automation setup.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Install System Dependencies](#step-1-install-system-dependencies)
4. [Step 2: Install Google Chrome](#step-2-install-google-chrome)
5. [Step 3: Install Clawdbot Browser Relay Extension](#step-3-install-clawdbot-browser-relay-extension)
6. [Step 4: Install Vision Click Tools](#step-4-install-vision-click-tools)
7. [Step 5: Create the Startup Script](#step-5-create-the-startup-script)
8. [Step 6: Configure Auto-Start on Boot](#step-6-configure-auto-start-on-boot)
9. [Step 7: Capture Extension Icon Template](#step-7-capture-extension-icon-template)
10. [Step 8: Verify Everything Works](#step-8-verify-everything-works)
11. [Usage Guide](#usage-guide)
12. [Troubleshooting](#troubleshooting)
13. [File Reference](#file-reference)

---

## Overview

### What This Does

This setup creates a headless Chrome browser that:
- Runs on a virtual display (Xvfb) - no physical monitor needed
- Has the Clawdbot Browser Relay extension installed
- Automatically clicks the extension on startup to attach tabs
- Can be controlled via `browser action=*` commands in Clawdbot
- Survives reboots and stays running persistently

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Xvfb :99 (Virtual Display 1920x1080)                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Fluxbox (Window Manager)                           │    │
│  │  ┌───────────────────────────────────────────────┐  │    │
│  │  │  Chrome (--remote-debugging-port=9222)        │  │    │
│  │  │  ┌─────────────────────────────────────────┐  │  │    │
│  │  │  │  Clawdbot Browser Relay Extension       │  │  │    │
│  │  │  │  (Attaches tabs for automation)         │  │  │    │
│  │  │  └─────────────────────────────────────────┘  │  │    │
│  │  └───────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              browser action=* profile=chrome
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **Xvfb** | Virtual framebuffer - provides a fake display |
| **Fluxbox** | Lightweight window manager - keeps Chrome stable |
| **Chrome** | Browser with remote debugging enabled |
| **Browser Relay Extension** | Connects tabs to Clawdbot for automation |
| **vclick** | Vision-based clicking tool |
| **zoomclick** | Iterative zoom-and-click tool with template saving |

---

## Prerequisites

- Ubuntu 20.04+ (tested on 22.04)
- Root/sudo access
- Internet connection
- Clawdbot installed and configured

---

## Step 1: Install System Dependencies

```bash
# Update package lists
sudo apt update

# Install Xvfb (virtual display)
sudo apt install -y xvfb

# Install Fluxbox (window manager)
sudo apt install -y fluxbox

# Install screenshot tools
sudo apt install -y scrot imagemagick

# Install Python dependencies for vision tools
sudo apt install -y python3-pip python3-opencv python3-numpy

# Install PyAutoGUI and other Python packages
pip3 install pyautogui pillow

# Install xdotool for keyboard/mouse automation
sudo apt install -y xdotool

# Install bc for floating point math in scripts
sudo apt install -y bc
```

### Verify Installation

```bash
# Check Xvfb
which Xvfb && echo "✓ Xvfb installed"

# Check Fluxbox  
which fluxbox && echo "✓ Fluxbox installed"

# Check scrot
which scrot && echo "✓ scrot installed"

# Check Python OpenCV
python3 -c "import cv2; print('✓ OpenCV version:', cv2.__version__)"

# Check PyAutoGUI
python3 -c "import pyautogui; print('✓ PyAutoGUI installed')"
```

---

## Step 2: Install Google Chrome

```bash
# Download Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# Install Chrome
sudo dpkg -i google-chrome-stable_current_amd64.deb

# Fix any dependency issues
sudo apt --fix-broken install -y

# Clean up
rm google-chrome-stable_current_amd64.deb

# Verify installation
google-chrome --version
```

---

## Step 3: Install Clawdbot Browser Relay Extension

The extension files should be in `~/.clawdbot/browser/chrome-extension/`. If Clawdbot is installed, they should already be there.

### Verify Extension Exists

```bash
ls -la ~/.clawdbot/browser/chrome-extension/
# Should show manifest.json and other extension files
```

### If Extension is Missing

Copy from the Clawdbot installation or download:

```bash
# Create directory
mkdir -p ~/.clawdbot/browser/chrome-extension

# The extension should be part of your Clawdbot installation
# Check clawdbot docs for extension location
```

---

## Step 4: Install Vision Click Tools

### Install vclick

```bash
# Clone vclick repository
cd ~
git clone https://github.com/aaron777collins/vclick.git

# Or if you have it locally, copy it:
# cp -r /path/to/vclick ~/vclick

# Verify it works
cd ~/vclick
python3 vclick.py --help
```

### Install zoomclick

```bash
# Clone zoomclick repository
cd ~
git clone https://github.com/aaron777collins/EnhanceAndClick.git zoomclick

# Or copy from clawdbot tools:
# cp -r ~/clawd/tools/zoomclick ~/zoomclick

# Create symlink for easy access
sudo ln -sf ~/zoomclick/zoomclick.py /usr/local/bin/zoomclick

# Create templates directory
mkdir -p ~/.zoomclick/templates

# Verify it works
cd ~/zoomclick
python3 zoomclick.py --help
```

---

## Step 5: Create the Startup Script

Create `$HOME/start-chrome-automation.sh`:

```bash
cat > $HOME/start-chrome-automation.sh << 'SCRIPT_EOF'
#!/bin/bash
# Chrome Automation Startup Script (Robust Version)
# Starts Xvfb + Fluxbox + Chrome with proper daemonization

DISPLAY_NUM=":99"
DEBUG_PORT=9222
USER_DATA_DIR="$HOME/.chrome-automation"
LOG_DIR="/tmp"
EXTENSION_COORDS="1752 32"  # Clawdbot extension icon location (fallback)

# Path to tools - adjust these if your installation differs
ZOOMCLICK_PATH="$HOME/zoomclick/zoomclick.py"
VCLICK_PATH="$HOME/vclick/vclick.py"

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
    
    # Create user data directory if it doesn't exist
    mkdir -p "$USER_DATA_DIR"
    
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
        --load-extension="$HOME/.clawdbot/browser/chrome-extension" \
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
        cd "$(dirname "$ZOOMCLICK_PATH")"
        RESULT=$(python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension_active" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        if [ "$(echo "$CONFIDENCE > 0.8" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "✓ Extension already active (detected ON state with confidence $CONFIDENCE)"
            return 0
        fi
    fi
    
    # Try zoomclick template first (for inactive state)
    if [ -f ~/.zoomclick/templates/clawdbot_extension.png ]; then
        log "Using zoomclick template for extension click"
        cd "$(dirname "$ZOOMCLICK_PATH")"
        RESULT=$(python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension" --no-click 2>/dev/null || true)
        CONFIDENCE=$(echo "$RESULT" | grep -o '"confidence": [0-9.]*' | grep -o '[0-9.]*' || echo "0")
        
        # Only use template match if confidence is high enough
        if [ "$(echo "$CONFIDENCE > 0.7" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            log "Template found with confidence $CONFIDENCE, clicking..."
            python3 "$ZOOMCLICK_PATH" --click "clawdbot_extension" 2>/dev/null
            log "✓ Extension clicked via template matching"
            return 0
        else
            log "Template confidence too low ($CONFIDENCE), using fallback coords"
        fi
    fi
    
    # Fall back to vclick with hardcoded coordinates
    log "Falling back to vclick coordinates ($EXTENSION_COORDS)"
    python3 "$VCLICK_PATH" --coords $EXTENSION_COORDS 2>/dev/null || true
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
    log "Browser:    browser action=tabs profile=chrome"
    log ""
    log "Startup complete."
}

main "$@"
SCRIPT_EOF

# Make it executable
chmod +x $HOME/start-chrome-automation.sh
```

### Verify Script Created

```bash
ls -la $HOME/start-chrome-automation.sh
head -20 $HOME/start-chrome-automation.sh
```

---

## Step 6: Configure Auto-Start on Boot

Add to crontab:

```bash
# Open crontab editor
crontab -e

# Add this line:
@reboot $HOME/start-chrome-automation.sh >> /tmp/chrome-automation.log 2>&1
```

Or use this one-liner:

```bash
(crontab -l 2>/dev/null | grep -v "start-chrome-automation"; echo "@reboot $HOME/start-chrome-automation.sh >> /tmp/chrome-automation.log 2>&1") | crontab -
```

### Verify Crontab

```bash
crontab -l | grep chrome
```

---

## Step 7: Capture Extension Icon Template

After starting Chrome for the first time, you need to capture the extension icon so zoomclick can find it.

### Start Chrome First

```bash
$HOME/start-chrome-automation.sh
```

### Take a Screenshot

```bash
DISPLAY=:99 scrot /tmp/full_screen.png
```

### Find the Extension Icon Location

The extension icon is typically in the top-right corner of Chrome's toolbar. You can:

1. **View the screenshot** and identify the icon's coordinates
2. **Use zoomclick interactively** to find it:

```bash
cd ~/zoomclick
DISPLAY=:99 python3 zoomclick.py --start
# Analyze the screenshot, zoom in to the extension icon
DISPLAY=:99 python3 zoomclick.py --zoom top-right
DISPLAY=:99 python3 zoomclick.py --zoom top
# Keep zooming until the icon is centered
DISPLAY=:99 python3 zoomclick.py --save "clawdbot_extension"
```

### Or Manually Crop the Icon

If you know the coordinates (typically around x=1740, y=20 for a 1920x1080 screen):

```bash
# Crop the extension icon (adjust coordinates as needed)
convert /tmp/full_screen.png -crop 24x24+1740+20 +repage ~/.zoomclick/templates/clawdbot_extension.png

# Create metadata file
cat > ~/.zoomclick/templates/clawdbot_extension.json << 'EOF'
{
  "name": "clawdbot_extension",
  "image": "$HOME/.zoomclick/templates/clawdbot_extension.png",
  "center_x": 1752,
  "center_y": 32,
  "notes": "Template for Clawdbot Browser Relay extension icon (inactive state)"
}
EOF
```

### Verify Template

```bash
ls -la ~/.zoomclick/templates/
# Should show clawdbot_extension.png and clawdbot_extension.json
```

---

## Step 8: Verify Everything Works

### Test 1: Check Processes

```bash
pgrep -a Xvfb && echo "✓ Xvfb running" || echo "✗ Xvfb NOT running"
pgrep -a fluxbox && echo "✓ Fluxbox running" || echo "✗ Fluxbox NOT running"
pgrep -f "chrome.*9222" && echo "✓ Chrome running" || echo "✗ Chrome NOT running"
```

### Test 2: Check DevTools

```bash
curl -s http://localhost:9222/json/version | head -3
```

### Test 3: Check Browser Tool (in Clawdbot)

```bash
browser action=tabs profile=chrome
```

Should return a list of tabs. If empty, the extension needs to be clicked:

```bash
DISPLAY=:99 python3 ~/zoomclick/zoomclick.py --click "clawdbot_extension"
```

### Test 4: Navigate and Screenshot

```bash
browser action=navigate profile=chrome targetUrl="https://example.com"
browser action=screenshot profile=chrome
```

---

## Usage Guide

### Basic Commands

```bash
# Check if browser is working
browser action=tabs profile=chrome

# Navigate to a URL
browser action=navigate profile=chrome targetUrl="https://example.com"

# Take a screenshot
browser action=screenshot profile=chrome

# Get page content as accessibility tree
browser action=snapshot profile=chrome

# Click an element (use refs from snapshot)
browser action=act profile=chrome request='{"kind": "click", "ref": "link \"Learn more\""}'

# Type in a field
browser action=act profile=chrome request='{"kind": "type", "ref": "textbox \"Search\"", "text": "hello world"}'
```

### If Extension Disconnects

```bash
# Click the extension to re-attach
DISPLAY=:99 python3 ~/zoomclick/zoomclick.py --click "clawdbot_extension"
```

### If Chrome Crashes

```bash
# Restart everything
$HOME/start-chrome-automation.sh
```

### Take Manual Screenshots

```bash
# Via scrot (full display)
DISPLAY=:99 scrot /tmp/screenshot.png

# View in terminal (if you have imgcat or similar)
# Or copy to a location you can access
```

---

## Troubleshooting

### Problem: `browser action=tabs` returns empty array

**Cause:** Extension not clicked / tab not attached.

**Solution:**
```bash
DISPLAY=:99 python3 ~/zoomclick/zoomclick.py --click "clawdbot_extension"
sleep 2
browser action=tabs profile=chrome
```

### Problem: Chrome won't start

**Cause:** Missing dependencies or display issues.

**Solution:**
```bash
# Check Xvfb is running
pgrep -a Xvfb || (Xvfb :99 -screen 0 1920x1080x24 &)
sleep 2

# Try starting Chrome manually
DISPLAY=:99 google-chrome --no-sandbox --disable-gpu "about:blank" &
```

### Problem: Extension click not working

**Cause:** Icon moved or template doesn't match.

**Solution:**
```bash
# Take fresh screenshot
DISPLAY=:99 scrot /tmp/debug.png

# Find the icon manually and update coordinates
# Then re-crop the template
convert /tmp/debug.png -crop 24x24+NEW_X+NEW_Y +repage ~/.zoomclick/templates/clawdbot_extension.png
```

### Problem: "Chrome didn't shut down correctly" popup

**Cause:** Chrome wasn't closed cleanly.

**Solution:** The startup script auto-fixes this, but manually:
```bash
python3 << 'EOF'
import json
prefs_file = '$HOME/.chrome-automation/Default/Preferences'
try:
    with open(prefs_file, 'r') as f:
        prefs = json.load(f)
    prefs['profile'] = prefs.get('profile', {})
    prefs['profile']['exit_type'] = 'Normal'
    prefs['profile']['exited_cleanly'] = True
    with open(prefs_file, 'w') as f:
        json.dump(prefs, f)
    print("Fixed!")
except Exception as e:
    print(f"Error: {e}")
EOF
```

### Problem: Processes die after SSH disconnect

**Cause:** Improper daemonization.

**Solution:** The startup script uses `setsid`, `nohup`, and `disown` together. If you're running commands manually, use:
```bash
setsid nohup COMMAND > /tmp/log.txt 2>&1 &
disown
```

---

## File Reference

| File | Purpose |
|------|---------|
| `$HOME/start-chrome-automation.sh` | Main startup script |
| `$HOME/.chrome-automation/` | Chrome user data directory |
| `~/.zoomclick/templates/clawdbot_extension.png` | Extension icon template |
| `~/.zoomclick/templates/clawdbot_extension.json` | Template metadata |
| `~/.clawdbot/browser/chrome-extension/` | Browser Relay extension files |
| `/tmp/xvfb.log` | Xvfb logs |
| `/tmp/fluxbox.log` | Fluxbox logs |
| `/tmp/chrome.log` | Chrome logs |
| `/tmp/chrome-automation.log` | Startup script logs |
| `~/vclick/vclick.py` | Vision click tool |
| `~/zoomclick/zoomclick.py` | Zoom and click tool |

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                 CLAWDBOT BROWSER QUICK REF                  │
├─────────────────────────────────────────────────────────────┤
│ START:     $HOME/start-chrome-automation.sh          │
│ CHECK:     browser action=tabs profile=chrome               │
│ NAVIGATE:  browser action=navigate profile=chrome           │
│            targetUrl="https://example.com"                  │
│ SCREENSHOT: browser action=screenshot profile=chrome        │
│ SNAPSHOT:  browser action=snapshot profile=chrome           │
├─────────────────────────────────────────────────────────────┤
│ IF TABS EMPTY:                                              │
│   DISPLAY=:99 zoomclick --click clawdbot_extension          │
├─────────────────────────────────────────────────────────────┤
│ DISPLAY: :99 | DEBUG PORT: 9222 | PROFILE: chrome           │
└─────────────────────────────────────────────────────────────┘
```

---

## Changelog

- **2026-01-27**: Initial version with full setup guide
