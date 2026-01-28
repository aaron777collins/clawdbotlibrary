# vclick - Vision Click Tool

A vision-based clicking tool that uses screenshots and coordinates for precise mouse control.

## Installation

```bash
# Dependencies
sudo apt install -y python3-pip python3-opencv scrot xdotool
pip3 install pyautogui pillow

# Copy to your preferred location
# Clone to ~/tools/vclick instead
```

## Usage

### Take Screenshot

```bash
# Full screen
python3 vclick.py --screenshot

# Specific window by title
python3 vclick.py --screenshot -w "Chrome"

# By window class
python3 vclick.py --screenshot --window-class "firefox"

# By window ID
python3 vclick.py --screenshot --window-id 12345

# Specific monitor (multi-monitor setup)
python3 vclick.py --screenshot --screen 1
```

### Click at Coordinates

```bash
# Single click
python3 vclick.py --coords 500 300
python3 vclick.py -c 500 300

# Double click
python3 vclick.py -c 500 300 --click-type double

# Right click
python3 vclick.py -c 500 300 --click-type right
```

### Template Matching

```bash
# Find and click an image template
python3 vclick.py --template button.png
python3 vclick.py -t button.png

# Find but don't click
python3 vclick.py -t button.png --no-click
```

### Click and Type

```bash
# Click then type text
python3 vclick.py -c 500 300 --type "hello world"

# Click then press key
python3 vclick.py -c 500 300 --key enter
```

### List Windows

```bash
python3 vclick.py --list-windows
```

## Output Format

All commands output JSON for easy parsing:

```json
{
  "success": true,
  "action": "click",
  "x": 500,
  "y": 300,
  "click_type": "single",
  "screenshot": "/tmp/vclick/screen_123456.png"
}
```

## Environment Variables

- `DISPLAY`: X display to use (default: `:0`, use `:99` for Xvfb)

## Examples

### AI-Assisted Workflow

1. Take screenshot:
   ```bash
   DISPLAY=:99 python3 vclick.py --screenshot
   ```

2. Analyze screenshot with vision model to get coordinates

3. Click the target:
   ```bash
   DISPLAY=:99 python3 vclick.py -c 500 300
   ```

### Automated Button Click

```bash
# Save a screenshot of the button as template
# Then use it to find and click:
DISPLAY=:99 python3 vclick.py --template submit_button.png
```

## Notes

- Uses `scrot` for screenshots (more reliable than PyAutoGUI on Xvfb)
- Uses `PyAutoGUI` for mouse/keyboard control
- Template matching uses OpenCV with adaptive confidence
- Screenshots are saved to `/tmp/vclick/`
