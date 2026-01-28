# zoomclick - Iterative Zoom-and-Click Tool

An AI-friendly tool for precise UI clicking through iterative zooming. Instead of guessing pixel coordinates from a full screenshot, progressively zoom into quadrants until your target is big and centered, then save it as a reusable template.

## Installation

```bash
# Dependencies
sudo apt install -y python3-pip python3-opencv scrot xdotool
pip3 install pyautogui pillow numpy

# Copy to your preferred location
# Clone to ~/tools/zoomclick instead

# Optional: create symlink for easy access
sudo ln -sf ~/tools/zoomclick/zoomclick.py /usr/local/bin/zoomclick

# Create templates directory
mkdir -p ~/.zoomclick/templates
```

## Workflow

### Step 1: Start a Session

```bash
zoomclick --start
```

Returns a screenshot with quadrant overlay lines. Analyze it and decide which quadrant contains your target.

### Step 2: Zoom Iteratively

```bash
zoomclick --zoom top-left      # or: top-right, bottom-left, bottom-right
zoomclick --zoom center        # zoom to center region
zoomclick --zoom top           # zoom to top edge
```

Each zoom returns a new cropped image with overlay. Keep zooming until your target element fills most of the image.

**Available directions:**
- Corners: `top-left`, `top-right`, `bottom-left`, `bottom-right`
- Edges: `top`, `bottom`, `left`, `right`
- Center: `center`

### Step 3: Save as Template

```bash
zoomclick --save "button_name"
```

Saves the current zoomed region as a named template:
- The cropped image (for template matching)
- The center coordinates (fallback if matching fails)

### Step 4: Click Anytime

```bash
zoomclick --click "button_name"
```

Finds the template on screen using OpenCV template matching and clicks its center. Falls back to saved coordinates if template not found.

## Commands Reference

| Command | Description |
|---------|-------------|
| `--start` | Start new session, take full screenshot with quadrant overlay |
| `--start -w "Title"` | Start on specific window by title (substring match) |
| `--start --window-class "class"` | Start on window by class name |
| `--start --window-id 12345` | Start on specific window ID |
| `--start --screen 1` | Start on specific screen (multi-monitor) |
| `--list-windows` | List all visible windows with IDs |
| `--zoom <direction>` | Zoom into quadrant/edge/center |
| `--save <name>` | Save current view as named template |
| `--click <name>` | Find and click saved template |
| `--click-center` | Click center of current viewport (without saving) |
| `--list` | List all saved templates |
| `--reset` | Reset zoom session |
| `--delete <name>` | Delete a saved template |
| `--no-click` | With --click, locate but don't click |

## Example Session

```bash
# Want to click a small "Submit" button on a webpage

# 1. Start zooming
DISPLAY=:99 zoomclick --start
# → Full screen with overlay. Button is in bottom-right.

DISPLAY=:99 zoomclick --zoom bottom-right
# → Zoomed in. Button now visible in top-left of this view.

DISPLAY=:99 zoomclick --zoom top-left
# → Button is big and centered!

# 2. Save it
DISPLAY=:99 zoomclick --save "submit_btn"
# → Template saved at ~/.zoomclick/templates/submit_btn.png

# 3. Later, click it anytime
DISPLAY=:99 zoomclick --click "submit_btn"
# → Finds button on screen, clicks it
```

## How Template Matching Works

1. Takes a fresh screenshot of the display
2. Uses OpenCV to find the template image on screen
3. Returns confidence score (0.0 - 1.0)
4. If confidence is high enough, clicks the matched location
5. If confidence is too low, falls back to saved coordinates

## Storage Locations

- **Working files:** `/tmp/zoomclick/` (screenshots, crops, overlay copies)
- **Templates:** `~/.zoomclick/templates/` (persistent, clean images)
- **State:** `/tmp/zoomclick/state.json` (current zoom session)

## How Overlays Work

The red/green guide lines are **only added to the output image** for navigation — they're never on the actual screen or saved templates.

- **Red lines:** Divide the screen into a 3x3 grid
- **Green box:** Shows the center region

Overlays are visual aids only, never captured or persisted.

## Tips

- Each zoom level halves the viewport dimensions
- The more you zoom, the more precise your template will be
- Use `--no-click` to test location without actually clicking
- If template matching fails often, recapture with a cleaner background

## Output Format

All commands output JSON:

```json
{
  "success": true,
  "action": "click",
  "name": "submit_btn",
  "x": 1752,
  "y": 32,
  "confidence": 0.85,
  "method": "template_match",
  "screenshot": "/tmp/zoomclick/click_123456.png"
}
```

## Environment Variables

- `DISPLAY`: X display to use (default: `:99`)
