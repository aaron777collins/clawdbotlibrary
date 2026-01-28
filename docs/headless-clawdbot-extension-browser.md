# Headless Chrome + Clawdbot Browser Relay Setup

> **Complete guide** to running Chrome with the Clawdbot Browser Relay extension on a headless server using Xvfb. Follow every step exactly.

## 🎯 What This Sets Up

- **Xvfb** - Virtual framebuffer (fake display)
- **Fluxbox** - Lightweight window manager (REQUIRED for Chrome to render)
- **Chrome** - Browser with remote debugging enabled
- **Clawdbot Browser Relay** - Extension for browser control
- **Screenshot tools** - ImageMagick's `import` command

## 📋 Prerequisites

- Ubuntu 22.04+ server
- Root or sudo access
- Clawdbot installed and configured

---

## Step 1: Install System Dependencies

```bash
# Update packages
sudo apt update

# Install Xvfb (virtual display)
sudo apt install -y xvfb

# Install Fluxbox (window manager - CRITICAL!)
sudo apt install -y fluxbox

# Install ImageMagick (for screenshots)
sudo apt install -y imagemagick

# Install xdotool (for window/keyboard control)
sudo apt install -y xdotool

# Install Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable
```

---

## Step 2: Start Xvfb (Virtual Display)

```bash
# Start Xvfb on display :99 with 1920x1080 resolution
Xvfb :99 -screen 0 1920x1080x24 &

# Verify it's running
ps aux | grep Xvfb
# Should show: Xvfb :99 -screen 0 1920x1080x24

# Set DISPLAY environment variable
export DISPLAY=:99
```

**To make Xvfb start on boot:**
```bash
# Create systemd service
sudo tee /etc/systemd/system/xvfb.service << 'EOF'
[Unit]
Description=X Virtual Frame Buffer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable xvfb
sudo systemctl start xvfb
```

---

## Step 3: Start Fluxbox Window Manager

> ⚠️ **CRITICAL**: Chrome WILL NOT RENDER without a window manager! Always start Fluxbox BEFORE Chrome.

```bash
export DISPLAY=:99
fluxbox &

# Verify it's running
pgrep fluxbox
# Should return a PID number
```

---

## Step 4: Create Chrome User Data Directory

```bash
# Create directory for Chrome profile
mkdir -p ~/.chrome-automation

# This stores the Chrome profile, extensions, and settings
```

---

## Step 5: Install Clawdbot Browser Relay Extension

The extension files should be at `~/.clawdbot/browser/chrome-extension/`.

If not present, copy from Clawdbot installation:
```bash
# Check if extension exists
ls ~/.clawdbot/browser/chrome-extension/manifest.json

# If missing, Clawdbot should create it on first run
```

---

## Step 6: Launch Chrome with Correct Flags

```bash
export DISPLAY=:99

google-chrome \
    --user-data-dir=$HOME/.chrome-automation \
    --remote-debugging-port=9222 \
    --no-first-run \
    --disable-gpu \
    --disable-software-rasterizer \
    --start-maximized \
    --load-extension=$HOME/.clawdbot/browser/chrome-extension \
    &

# Wait for Chrome to start
sleep 5

# Verify Chrome is running
pgrep chrome
curl -s http://localhost:9222/json | head -5
```

### Chrome Flags Explained

| Flag | Purpose |
|------|---------|
| `--user-data-dir` | Separate profile for automation |
| `--remote-debugging-port=9222` | Enable DevTools Protocol |
| `--no-first-run` | Skip first-run dialogs |
| `--disable-gpu` | Required for Xvfb (no GPU) |
| `--disable-software-rasterizer` | Helps with rendering issues |
| `--start-maximized` | Full screen window |
| `--load-extension` | Load the Clawdbot extension |

---

## Step 7: Take Screenshots

> ⚠️ **IMPORTANT**: Use `import` from ImageMagick, NOT `scrot`! Scrot produces black images with Chrome on Xvfb.

```bash
# Take a screenshot
DISPLAY=:99 import -window root /tmp/screenshot.png

# View it (or transfer to your machine)
ls -la /tmp/screenshot.png
```

### Why `import` works but `scrot` doesn't:
- Chrome uses software rendering on Xvfb
- `scrot` has issues with Chrome's compositor
- `import` captures the X framebuffer directly

---

## Step 8: Using ZoomClick for UI Interaction

ZoomClick is an AI-friendly tool for finding and clicking UI elements:

```bash
# Start a zoom session
DISPLAY=:99 zoomclick --start

# Zoom into a region (8 directions available)
DISPLAY=:99 zoomclick --zoom top-right   # or: ne, nw, sw, se
DISPLAY=:99 zoomclick --zoom top         # or: n, s, e, w
DISPLAY=:99 zoomclick --zoom center
DISPLAY=:99 zoomclick --zoom center-n    # exclude bottom

# Save current view as a clickable template
DISPLAY=:99 zoomclick --save "extension_icon"

# Click a saved template anytime
DISPLAY=:99 zoomclick --click "extension_icon"

# Click current center without saving
DISPLAY=:99 zoomclick --click-center
```

---

## Complete Startup Script

Save this as `/home/ubuntu/start-chrome-xvfb.sh`:

```bash
#!/bin/bash
# Start Chrome on Xvfb display :99 with proper rendering

DISPLAY_NUM=:99
USER_DATA_DIR=$HOME/.chrome-automation
DEBUG_PORT=9222
EXTENSION_DIR=$HOME/.clawdbot/browser/chrome-extension

export DISPLAY=$DISPLAY_NUM

echo "Starting Chrome automation environment..."

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
echo "✓ Fluxbox running (PID: $(pgrep -x fluxbox))"

# Build Chrome command
CHROME_CMD="google-chrome"
CHROME_CMD="$CHROME_CMD --user-data-dir=$USER_DATA_DIR"
CHROME_CMD="$CHROME_CMD --remote-debugging-port=$DEBUG_PORT"
CHROME_CMD="$CHROME_CMD --no-first-run"
CHROME_CMD="$CHROME_CMD --disable-gpu"
CHROME_CMD="$CHROME_CMD --disable-software-rasterizer"
CHROME_CMD="$CHROME_CMD --start-maximized"

# Add extension if it exists
if [ -d "$EXTENSION_DIR" ]; then
    CHROME_CMD="$CHROME_CMD --load-extension=$EXTENSION_DIR"
    echo "✓ Loading Clawdbot extension"
fi

# Start Chrome
echo "Starting Chrome..."
$CHROME_CMD 2>/dev/null &
sleep 5

# Verify Chrome is running
if ! pgrep -f "chrome.*$DEBUG_PORT" > /dev/null; then
    echo "ERROR: Chrome failed to start!"
    exit 1
fi

echo "✓ Chrome running with DevTools on port $DEBUG_PORT"
echo ""
echo "Test commands:"
echo "  Screenshot: DISPLAY=$DISPLAY_NUM import -window root /tmp/test.png"
echo "  DevTools:   curl -s http://localhost:$DEBUG_PORT/json | head"
echo "  ZoomClick:  DISPLAY=$DISPLAY_NUM zoomclick --start"
```

Make it executable:
```bash
chmod +x /home/ubuntu/start-chrome-xvfb.sh
```

---

## Troubleshooting

### Black Screenshots
**Symptom**: Screenshots show only black
**Cause**: Fluxbox not running or Chrome started before fluxbox
**Fix**:
```bash
# Check if fluxbox is running
pgrep fluxbox || echo "Fluxbox not running!"

# Restart everything in correct order
killall chrome fluxbox
DISPLAY=:99 fluxbox &
sleep 2
# Then start Chrome
```

### Chrome Not Rendering
**Symptom**: Chrome process runs but window is empty
**Cause**: Missing `--disable-gpu` flag or window manager
**Fix**: Ensure Chrome command includes `--disable-gpu --disable-software-rasterizer`

### Extension Not Loading
**Symptom**: Clawdbot extension icon not in toolbar
**Cause**: Extension path wrong or Chrome blocked it
**Fix**:
```bash
# Verify extension path
ls ~/.clawdbot/browser/chrome-extension/manifest.json

# If missing, check Clawdbot config
cat ~/.clawdbot/config.yaml | grep -A5 browser
```

### DevTools Connection Refused
**Symptom**: `curl localhost:9222` fails
**Cause**: Chrome crashed or port blocked
**Fix**:
```bash
# Check if Chrome is using the port
netstat -tlnp | grep 9222

# Restart Chrome
killall chrome
# Run start script again
```

### Display Not Found
**Symptom**: "Cannot open display :99"
**Cause**: Xvfb not running
**Fix**:
```bash
# Check if Xvfb is running
ps aux | grep Xvfb

# Start it if not
Xvfb :99 -screen 0 1920x1080x24 &
```

---

## Quick Reference

```bash
# Start everything
/home/ubuntu/start-chrome-xvfb.sh

# Take screenshot
DISPLAY=:99 import -window root /tmp/screenshot.png

# Interactive zoom-click
DISPLAY=:99 zoomclick --start
DISPLAY=:99 zoomclick --zoom ne
DISPLAY=:99 zoomclick --save "button_name"
DISPLAY=:99 zoomclick --click "button_name"

# Check processes
pgrep fluxbox && echo "Fluxbox OK" || echo "Fluxbox DOWN"
pgrep chrome && echo "Chrome OK" || echo "Chrome DOWN"
curl -s localhost:9222/json | head -1

# Restart everything
killall chrome fluxbox; /home/ubuntu/start-chrome-xvfb.sh
```

---

## Order of Operations (MEMORIZE THIS!)

1. **Xvfb** must be running (usually via systemd)
2. **Fluxbox** must start BEFORE Chrome
3. **Chrome** starts AFTER fluxbox with `--disable-gpu`
4. **Screenshots** use `import -window root`, NOT `scrot`
5. **ZoomClick** for finding and clicking UI elements

---

## See Also

- [ZoomClick Documentation](zoomclick.md)
- [VClick Documentation](vclick.md)
- [Main README](../README.md)
