# Scripts

Setup and startup scripts for Chrome automation.

## Quick Start

```bash
# Full setup on a fresh server (run as root)
sudo ./setup-all.sh

# Start Chrome automation
$HOME/start-chrome-automation.sh

# Test it
DISPLAY=:99 scrot /tmp/test.png
```

## Scripts

### setup-all.sh

**Complete setup script.** Run this on a fresh server to install everything.

```bash
# Full setup (recommended)
sudo ./setup-all.sh

# Skip system deps (if already installed)
./setup-all.sh --no-root
```

What it does:
1. Installs system dependencies (Xvfb, fluxbox, Chrome, etc.)
2. Installs Python packages (pyautogui, opencv-python, pillow, numpy)
3. Clones and installs vclick from GitHub
4. Clones and installs zoomclick from GitHub
5. Copies startup script to `$HOME/`
6. Sets up Xvfb as a systemd service
7. Adds crontab entry for auto-start on reboot

### install-deps.sh

**System dependencies only.** Run this separately if you just need the packages.

```bash
sudo ./install-deps.sh
```

Installs:
- `xvfb` - Virtual framebuffer
- `fluxbox` - Window manager (required for Chrome)
- `scrot` - Screenshot tool
- `imagemagick` - Image processing
- `xdotool` - X11 automation
- `google-chrome-stable` - Chrome browser
- Python packages: pyautogui, opencv-python, pillow, numpy

### start-chrome-automation.sh

**Startup script.** Launches the full automation stack.

```bash
$HOME/start-chrome-automation.sh
```

What it does (in order):
1. Kills any existing Xvfb/fluxbox/Chrome processes
2. Starts Xvfb on display :99 (or uses existing systemd service)
3. Starts fluxbox window manager
4. Fixes Chrome preferences (suppresses crash dialog)
5. Starts Chrome with remote debugging on port 9222
6. Clicks the Clawdbot extension icon (if templates exist)

Configuration (edit the script to change):
```bash
DISPLAY_NUM=":99"           # Virtual display number
DEBUG_PORT=9222             # Chrome DevTools port
USER_DATA_DIR="$HOME/.chrome-automation"  # Chrome profile
EXTENSION_COORDS="1752 32"  # Fallback click coordinates
TOOLS_DIR="$HOME/tools"     # Where vclick/zoomclick are installed
```

## File Locations After Setup

| Path | Description |
|------|-------------|
| `$HOME/start-chrome-automation.sh` | Startup script |
| `$HOME/tools/vclick/` | vclick tool |
| `$HOME/tools/zoomclick/` | zoomclick tool |
| `$HOME/.chrome-automation/` | Chrome profile data |
| `$HOME/.zoomclick/templates/` | Saved click templates |
| `/usr/local/bin/vclick` | Symlink to vclick |
| `/usr/local/bin/zoomclick` | Symlink to zoomclick |

## Logs

| Log | Description |
|-----|-------------|
| `/tmp/chrome-automation.log` | Startup script output |
| `/tmp/xvfb.log` | Xvfb output |
| `/tmp/fluxbox.log` | Fluxbox output |
| `/tmp/chrome.log` | Chrome output |

## Crontab

The setup adds this to your crontab:
```
@reboot $HOME/start-chrome-automation.sh >> /tmp/chrome-automation.log 2>&1
```

To remove:
```bash
crontab -e
# Delete the line with start-chrome-automation.sh
```

## Troubleshooting

### "Xvfb failed to start"
- Check if already running: `pgrep -a Xvfb`
- Check logs: `cat /tmp/xvfb.log`
- Check systemd: `systemctl status xvfb`

### "Chrome failed to start"
- Check logs: `cat /tmp/chrome.log`
- Make sure fluxbox is running: `pgrep fluxbox`
- Try manual start: `DISPLAY=:99 google-chrome --no-sandbox &`

### "Black screenshots"
- Make sure fluxbox started BEFORE Chrome
- Restart everything: `$HOME/start-chrome-automation.sh`

### Extension not clicking
- Create templates first: `DISPLAY=:99 zoomclick --start`
- See [headless-browser-setup.md](../docs/headless-browser-setup.md) for details

## GitHub Repositories

| Tool | Repository |
|------|------------|
| vclick | https://github.com/aaron777collins/vclick |
| zoomclick | https://github.com/aaron777collins/EnhanceAndClick |
| clawdbotlibrary | https://github.com/aaron777collins/clawdbotlibrary |
