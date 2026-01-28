# Scripts

Automation scripts for Clawdbot.

## start-chrome-automation.sh

Robust startup script for headless Chrome with Clawdbot Browser Relay.

### What It Does

1. **Kills existing processes** (clean start)
2. **Starts Xvfb** on display :99 (1920x1080)
3. **Starts Fluxbox** window manager (required for Chrome stability)
4. **Fixes Chrome preferences** (prevents "didn't shut down correctly" prompts)
5. **Starts Chrome** with:
   - `--remote-debugging-port=9222`
   - Anti-detection flags
   - Browser Relay extension loaded
6. **Clicks extension** via zoomclick template (or fallback coordinates)

### Features

- **Proper daemonization:** Uses `setsid`, `nohup`, and `disown` to ensure processes survive shell exit
- **Auto-recovery:** Fixes Chrome crash prompts automatically
- **Template matching:** Uses zoomclick to find and click extension icon reliably
- **Fallback coords:** Falls back to hardcoded coordinates if template matching fails
- **Logging:** All output logged to `/tmp/chrome-automation.log`

### Installation

```bash
# Copy to home directory
cp start-chrome-automation.sh ~/

# Make executable
chmod +x ~/start-chrome-automation.sh

# Set up auto-start on boot
(crontab -l 2>/dev/null | grep -v "start-chrome-automation"; echo "@reboot $HOME/start-chrome-automation.sh >> /tmp/chrome-automation.log 2>&1") | crontab -
```

### Usage

```bash
# Start manually
$HOME/start-chrome-automation.sh

# Check if running
pgrep -a Xvfb && echo "Xvfb OK"
pgrep -a fluxbox && echo "Fluxbox OK"
pgrep -f "chrome.*9222" && echo "Chrome OK"

# Check logs
cat /tmp/chrome-automation.log
```

### Configuration

Edit the script to change these variables:

```bash
DISPLAY_NUM=":99"           # Virtual display number
DEBUG_PORT=9222             # Chrome DevTools port
USER_DATA_DIR="$HOME/.chrome-automation"   # Chrome profile location
EXTENSION_COORDS="1752 32"  # Fallback coordinates for extension icon
```

### Dependencies

- Xvfb
- Fluxbox
- Google Chrome
- Python 3 with pyautogui, opencv
- vclick and zoomclick tools
- Clawdbot Browser Relay extension

### Troubleshooting

**Chrome won't start:**
```bash
# Check Chrome logs
cat /tmp/chrome.log

# Try starting manually
DISPLAY=:99 google-chrome --no-sandbox --disable-gpu "about:blank" &
```

**Extension not clicked:**
```bash
# Check zoomclick template exists
ls -la ~/.zoomclick/templates/clawdbot_extension.*

# Try manual click
DISPLAY=:99 python3 ~/zoomclick/zoomclick.py --click "clawdbot_extension"
```

**Processes die after SSH disconnect:**
The script uses proper daemonization. If running manually, use:
```bash
nohup $HOME/start-chrome-automation.sh > /tmp/startup.log 2>&1 &
disown
```
