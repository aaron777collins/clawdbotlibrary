# VClick - Vision Click Tool

> Direct coordinate clicking with vision support and template matching.

**GitHub Repository:** https://github.com/aaron777collins/vclick

## 🎯 When to Use VClick vs ZoomClick

| Use VClick when... | Use ZoomClick when... |
|--------------------|-----------------------|
| You know exact coordinates | Target is small/hard to find |
| Quick one-shot clicks | Need iterative navigation |
| Template matching | Building reusable templates |
| Direct automation | AI-assisted exploration |

## 📋 Installation

```bash
# Install system dependencies
sudo apt install -y scrot imagemagick xdotool python3-pip

# Install Python dependencies
pip install pyautogui opencv-python numpy pillow

# Clone the repository
git clone https://github.com/aaron777collins/vclick.git ~/tools/vclick
cd ~/tools/vclick

# Optional: Add to PATH
sudo ln -sf $(pwd)/vclick.py /usr/local/bin/vclick
```

## 🚀 Basic Commands

### Take Screenshot
```bash
DISPLAY=:99 vclick --screenshot
# Saves to /tmp/vclick_screenshot.png
```

### Click at Coordinates
```bash
DISPLAY=:99 vclick --coords 500 300
DISPLAY=:99 vclick -c 500 300

# Double-click
DISPLAY=:99 vclick -c 500 300 --click-type double

# Right-click
DISPLAY=:99 vclick -c 500 300 --click-type right
```

### Template Matching
```bash
# Find and click an image on screen
DISPLAY=:99 vclick --template button.png

# Find without clicking
DISPLAY=:99 vclick --template button.png --no-click
```

### Click and Type
```bash
# Click then type text
DISPLAY=:99 vclick -c 500 300 --type "hello world"

# Click then press key
DISPLAY=:99 vclick -c 500 300 --key enter
```

## 🖼️ Window Targeting

```bash
# List all windows
DISPLAY=:99 vclick --list-windows

# Screenshot specific window
DISPLAY=:99 vclick --screenshot --window "Chrome"
DISPLAY=:99 vclick --screenshot --window-class "firefox"
DISPLAY=:99 vclick --screenshot --window-id 12345

# Click in specific window (translates coordinates)
DISPLAY=:99 vclick -c 100 50 --window "Chrome"
```

## 📖 Workflow Example

```bash
# 1. Take screenshot
DISPLAY=:99 vclick --screenshot

# 2. AI analyzes screenshot and identifies target at (750, 420)

# 3. Click target
DISPLAY=:99 vclick -c 750 420

# 4. Type in the clicked field
DISPLAY=:99 vclick -c 750 420 --type "search query"
```

## 🔧 All Options

| Option | Description |
|--------|-------------|
| `--screenshot` | Take screenshot |
| `--coords X Y` / `-c X Y` | Click at coordinates |
| `--template FILE` / `-t FILE` | Find and click template |
| `--no-click` | Find only, don't click |
| `--click-type TYPE` | `single`, `double`, or `right` |
| `--type TEXT` | Type text after clicking |
| `--key KEY` | Press key after clicking |
| `--window TITLE` | Target window by title |
| `--window-class CLASS` | Target window by class |
| `--window-id ID` | Target window by ID |
| `--list-windows` | List all windows |

## 💡 Tips

1. **Window-relative coords**: When using `--window`, coordinates are relative to the window
2. **Template confidence**: Template matching uses adaptive confidence (starts at 100%, decreases until found)
3. **JSON output**: All commands output JSON for easy parsing

## 📝 JSON Output

```json
{
  "success": true,
  "action": "click",
  "x": 500,
  "y": 300,
  "screenshot": "/tmp/vclick_screenshot.png"
}
```

## See Also

- [ZoomClick Documentation](zoomclick.md) - For iterative zoom navigation
- [Headless Browser Setup](headless-clawdbot-extension-browser.md)
