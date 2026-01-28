# ZoomClick - AI-Friendly UI Automation

> Iterative zoom-and-click tool for precise UI element targeting. Instead of guessing pixel coordinates, progressively zoom until your target is big and centered.

**GitHub Repository:** https://github.com/aaron777collins/EnhanceAndClick

## 🎯 Why ZoomClick?

When an AI looks at a screenshot, small UI elements (like toolbar icons) are hard to pinpoint. ZoomClick solves this by:

1. Showing the screen with a navigation grid
2. Letting you zoom into regions iteratively
3. Saving templates for one-click access later

## 📋 Requirements

- Python 3.10+
- ImageMagick (`import`, `convert` commands)
- xdotool
- PyAutoGUI
- OpenCV (for template matching)

## 🚀 Installation

```bash
# Install system dependencies
sudo apt install -y imagemagick xdotool python3-pip

# Install Python dependencies
pip install pyautogui opencv-python numpy pillow

# Clone the repository
git clone https://github.com/aaron777collins/EnhanceAndClick.git ~/tools/zoomclick
cd ~/tools/zoomclick

# Create template storage
mkdir -p ~/.zoomclick/templates

# Optional: Add to PATH
sudo ln -sf $(pwd)/zoomclick.py /usr/local/bin/zoomclick
```

## 📖 Basic Usage

### Step 1: Start a Session

```bash
DISPLAY=:99 zoomclick --start
```

This takes a full screenshot and shows it with a 3x3 navigation grid.

### Step 2: Zoom Into Regions

```bash
# Corners (50% of screen)
zoomclick --zoom top-left      # or: nw
zoomclick --zoom top-right     # or: ne
zoomclick --zoom bottom-left   # or: sw
zoomclick --zoom bottom-right  # or: se

# Edges (1/3 strip)
zoomclick --zoom top           # or: n
zoomclick --zoom bottom        # or: s
zoomclick --zoom left          # or: w
zoomclick --zoom right         # or: e

# Center (middle 50%)
zoomclick --zoom center
```

### Step 3: Exclusion Zones

Zoom to "everything except" a region:

```bash
# Exclude edges
zoomclick --zoom center-n      # Top 2/3 (exclude bottom)
zoomclick --zoom center-s      # Bottom 2/3 (exclude top)
zoomclick --zoom center-e      # Right 2/3 (exclude left)
zoomclick --zoom center-w      # Left 2/3 (exclude right)

# Exclude corners
zoomclick --zoom exclude-nw    # Everything except top-left
zoomclick --zoom exclude-ne    # Everything except top-right
zoomclick --zoom exclude-sw    # Everything except bottom-left
zoomclick --zoom exclude-se    # Everything except bottom-right
```

### Step 4: Save Template

When your target is big and centered:

```bash
zoomclick --save "submit_button"
```

This saves:
- Template image for matching
- Center coordinates for clicking

### Step 5: Click Later

```bash
# Click a saved template
zoomclick --click "submit_button"

# Just locate without clicking
zoomclick --click "submit_button" --no-click
```

## 📍 Direction Reference

```
         top (n)
           │
    nw ────┼──── ne
           │
left (w) ──┼── right (e)
           │
    sw ────┼──── se
           │
       bottom (s)

center = middle 50% (green box)
```

## 🔧 All Commands

| Command | Description |
|---------|-------------|
| `--start` | Start new session with screenshot |
| `--zoom <dir>` | Zoom into direction |
| `--save <name>` | Save current view as template |
| `--click <name>` | Find and click saved template |
| `--click-center` | Click center of current view |
| `--list` | List all saved templates |
| `--reset` | Reset zoom session |
| `--delete <name>` | Delete a template |
| `--list-windows` | List all visible windows |

## 🖼️ Window Targeting

Focus on a specific window instead of full screen:

```bash
# By window title (substring match)
zoomclick --start --window "Chrome"

# By window class
zoomclick --start --window-class "firefox"

# By window ID
zoomclick --start --window-id 12345

# By screen number (multi-monitor)
zoomclick --start --screen 0
```

## 📁 File Locations

| Location | Purpose |
|----------|---------|
| `/tmp/zoomclick/` | Working files (screenshots, crops) |
| `~/.zoomclick/templates/` | Saved templates (persistent) |
| `/tmp/zoomclick/state.json` | Current zoom session state |

## 💡 Tips for AI Agents

1. **Always start fresh**: `zoomclick --reset` then `--start`
2. **Read the screenshot**: Analyze the overlay image to decide direction
3. **Zoom until big**: Keep zooming until target fills most of the image
4. **Save templates**: Templates can be clicked without re-zooming
5. **Use exclusions**: `center-n` is great for "top part of screen"

## 🔄 Example Workflow

Finding and clicking the Clawdbot extension icon:

```bash
# 1. Start fresh
DISPLAY=:99 zoomclick --reset
DISPLAY=:99 zoomclick --start
# → See full screen with grid, extension icon is in top-right

# 2. Zoom to top-right
DISPLAY=:99 zoomclick --zoom ne
# → Now showing top-right quadrant, icon more visible

# 3. Zoom to top edge
DISPLAY=:99 zoomclick --zoom top
# → Now showing toolbar area

# 4. Zoom to right side
DISPLAY=:99 zoomclick --zoom right
# → Icon should be big and centered now

# 5. Save it
DISPLAY=:99 zoomclick --save "clawdbot_extension"
# → Template saved!

# 6. Click anytime
DISPLAY=:99 zoomclick --click "clawdbot_extension"
```

## ⚠️ Common Issues

### Black Screenshots
Use `import -window root` internally. If screenshots are black, Chrome or Fluxbox crashed. Restart them.

### Template Not Found
Template matching failed. Either:
- UI changed since template was saved
- Screen content different
- Falls back to saved coordinates

### "No active session"
Run `zoomclick --start` before zooming.

## 📝 JSON Output

ZoomClick outputs JSON for easy parsing:

```json
{
  "success": true,
  "action": "zoom",
  "direction": "top-right",
  "screenshot": "/tmp/zoomclick/overlay_1.png",
  "viewport": {
    "x": 960,
    "y": 0,
    "width": 960,
    "height": 540,
    "zoom_level": 1
  },
  "screen_coords": {
    "center_x": 1440,
    "center_y": 270
  }
}
```

## See Also

- [Headless Browser Setup](headless-browser-setup.md)
- [VClick Documentation](vclick.md)
