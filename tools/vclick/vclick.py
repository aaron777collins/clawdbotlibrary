#!/usr/bin/env python3
"""
vclick - Vision-based clicking tool for Sophie

Inspired by Control-Windows (github.com/aaron777collins/Control-Windows).
Takes a screenshot, can find template images using OpenCV, and clicks via PyAutoGUI.

Usage:
  vclick --screenshot                    # just take screenshot
  vclick --coords X Y                    # click specific coordinates  
  vclick --template image.png            # find and click template image (like Control-Windows "x" action)
  vclick "description"                   # output screenshot for AI vision analysis

Window/Screen Targeting:
  vclick --screenshot --window "Chrome"       # capture window by title (substring match)
  vclick --screenshot --window-class "firefox" # capture window by class
  vclick --screenshot --window-id 12345       # capture specific window ID
  vclick --screenshot --screen 1              # capture specific screen (multi-monitor)
  vclick --list-windows                       # list all windows with IDs

Examples:
  vclick --screenshot                    # Take screenshot, output path
  vclick -c 500 300                      # Click at (500, 300)
  vclick -c 500 300 --click-type double  # Double-click
  vclick -t button.png                   # Find button.png on screen, click center
  vclick -t button.png --no-click        # Find but don't click (just report coords)
  vclick "the blue Submit button"        # Output screenshot for AI to analyze
  vclick --screenshot -w "Firefox"       # Screenshot of Firefox window only
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# Set display before importing pyautogui
os.environ.setdefault('DISPLAY', ':99')

# Suppress mouseinfo tkinter warning
sys.modules['mouseinfo'] = type(sys)('mouseinfo')

import pyautogui

# Safety settings
pyautogui.FAILSAFE = True  # Move mouse to corner to abort
pyautogui.PAUSE = 0.1      # Small pause between actions

SCREENSHOT_DIR = Path("/tmp/vclick")
SCREENSHOT_DIR.mkdir(exist_ok=True)

def find_window_by_name(name: str) -> list:
    """Find window IDs by title (substring match)."""
    try:
        result = subprocess.run(
            ['xdotool', 'search', '--name', name],
            capture_output=True, text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return [int(wid) for wid in result.stdout.strip().split('\n') if wid]
    except Exception:
        pass
    return []

def find_window_by_class(class_name: str) -> list:
    """Find window IDs by class."""
    try:
        result = subprocess.run(
            ['xdotool', 'search', '--class', class_name],
            capture_output=True, text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return [int(wid) for wid in result.stdout.strip().split('\n') if wid]
    except Exception:
        pass
    return []

def get_window_geometry(window_id: int) -> dict:
    """Get window position and size."""
    try:
        result = subprocess.run(
            ['xdotool', 'getwindowgeometry', '--shell', str(window_id)],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            geo = {}
            for line in result.stdout.strip().split('\n'):
                if '=' in line:
                    key, val = line.split('=', 1)
                    geo[key] = int(val) if val.isdigit() else val
            return geo
    except Exception:
        pass
    return {}

def list_windows() -> list:
    """List all windows with IDs, names, and geometry."""
    windows = []
    try:
        # Get all window IDs
        result = subprocess.run(
            ['xdotool', 'search', '--onlyvisible', '--name', ''],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            for wid in result.stdout.strip().split('\n'):
                if not wid:
                    continue
                wid = int(wid)
                # Get window name
                name_result = subprocess.run(
                    ['xdotool', 'getwindowname', str(wid)],
                    capture_output=True, text=True
                )
                name = name_result.stdout.strip() if name_result.returncode == 0 else ""
                
                # Get geometry
                geo = get_window_geometry(wid)
                
                windows.append({
                    "id": wid,
                    "name": name,
                    "x": geo.get("X", 0),
                    "y": geo.get("Y", 0),
                    "width": geo.get("WIDTH", 0),
                    "height": geo.get("HEIGHT", 0)
                })
    except Exception as e:
        pass
    return windows

def take_screenshot_window(window_id: int, name="window") -> Path:
    """Take screenshot of a specific window using ImageMagick import."""
    timestamp = int(time.time())
    path = SCREENSHOT_DIR / f"{name}_{timestamp}.png"
    
    display = os.environ.get('DISPLAY', ':99')
    result = subprocess.run(
        ['import', '-window', str(window_id), str(path)],
        env={**os.environ, 'DISPLAY': display},
        capture_output=True
    )
    
    if result.returncode != 0:
        raise RuntimeError(f"Window screenshot failed: {result.stderr.decode()}")
    
    return path

def take_screenshot_screen(screen_num: int, name="screen") -> Path:
    """Take screenshot of a specific screen (multi-monitor)."""
    timestamp = int(time.time())
    path = SCREENSHOT_DIR / f"{name}_{timestamp}.png"
    
    display = os.environ.get('DISPLAY', ':99')
    
    # Get screen geometry using xrandr
    try:
        result = subprocess.run(['xrandr'], capture_output=True, text=True)
        screens = []
        for line in result.stdout.split('\n'):
            if ' connected' in line:
                # Parse geometry like "1920x1080+0+0"
                import re
                match = re.search(r'(\d+)x(\d+)\+(\d+)\+(\d+)', line)
                if match:
                    screens.append({
                        'width': int(match.group(1)),
                        'height': int(match.group(2)),
                        'x': int(match.group(3)),
                        'y': int(match.group(4))
                    })
        
        if screen_num >= len(screens):
            raise RuntimeError(f"Screen {screen_num} not found. Available: 0-{len(screens)-1}")
        
        s = screens[screen_num]
        # Use scrot to capture full screen, then crop
        full_path = SCREENSHOT_DIR / f"full_{timestamp}.png"
        subprocess.run(['scrot', str(full_path)], env={**os.environ, 'DISPLAY': display}, check=True)
        
        # Crop to specific screen using ImageMagick
        subprocess.run([
            'convert', str(full_path),
            '-crop', f"{s['width']}x{s['height']}+{s['x']}+{s['y']}",
            '+repage', str(path)
        ], check=True)
        
        full_path.unlink()  # Clean up
        return path
        
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Screen screenshot failed: {e}")

def take_screenshot(name="screen"):
    """Take a screenshot using scrot (pyautogui.screenshot needs gnome-screenshot on Linux)."""
    timestamp = int(time.time())
    path = SCREENSHOT_DIR / f"{name}_{timestamp}.png"
    
    display = os.environ.get('DISPLAY', ':99')
    result = subprocess.run(
        ['scrot', str(path)],
        env={**os.environ, 'DISPLAY': display},
        capture_output=True
    )
    
    if result.returncode != 0:
        raise RuntimeError(f"Screenshot failed: {result.stderr.decode()}")
    
    return path

def get_screen_size():
    """Get screen dimensions."""
    return pyautogui.size()

def click_at(x, y, click_type="single"):
    """Click at coordinates using PyAutoGUI."""
    pyautogui.moveTo(x, y, duration=0.25)
    
    if click_type == "double":
        pyautogui.doubleClick(x, y, interval=0.1)
    elif click_type == "right":
        pyautogui.rightClick(x, y)
    else:
        pyautogui.click(x, y)
    
    return True

def type_text(text, interval=0.05):
    """Type text using PyAutoGUI."""
    pyautogui.write(text, interval=interval)

def press_key(key):
    """Press a key using PyAutoGUI."""
    pyautogui.press(key)

def hotkey(*keys):
    """Press a hotkey combination using PyAutoGUI."""
    pyautogui.hotkey(*keys)

def find_template(screen_path, template_path, min_confidence=0.5):
    """
    Find a template image on screen using OpenCV template matching.
    Like Control-Windows "x" action - decreases confidence until found.
    Returns (x, y, confidence) or None.
    """
    try:
        import cv2
        import numpy as np
    except ImportError:
        return None
    
    screen = cv2.imread(str(screen_path))
    template = cv2.imread(str(template_path))
    
    if screen is None or template is None:
        return None
    
    # Adaptive confidence matching (like Control-Windows)
    confidence = 1.0
    while confidence >= min_confidence:
        result = cv2.matchTemplate(screen, template, cv2.TM_CCOEFF_NORMED)
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
        
        if max_val >= confidence:
            h, w = template.shape[:2]
            center_x = max_loc[0] + w // 2
            center_y = max_loc[1] + h // 2
            return (center_x, center_y, max_val)
        
        confidence -= 0.1
    
    return None

def main():
    parser = argparse.ArgumentParser(
        description="Vision-based clicking tool (PyAutoGUI + OpenCV)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("description", nargs="?", help="Description of what to click (for AI vision)")
    parser.add_argument("--screenshot", "-s", action="store_true", help="Just take screenshot")
    parser.add_argument("--coords", "-c", nargs=2, type=int, metavar=("X", "Y"), help="Click at coordinates")
    parser.add_argument("--template", "-t", help="Template image to find and click")
    parser.add_argument("--click-type", choices=["single", "double", "right"], default="single")
    parser.add_argument("--no-click", action="store_true", help="Find but don't click")
    parser.add_argument("--confidence", type=float, default=0.5, help="Min confidence for template (0.0-1.0)")
    parser.add_argument("--type", dest="type_text", help="Type text after clicking")
    parser.add_argument("--key", help="Press key after clicking (e.g., 'enter', 'tab')")
    parser.add_argument("--display", "-d", default=":99", help="X display (default :99)")
    
    # Window/screen targeting options
    parser.add_argument("--window", "-w", help="Capture window by title (substring match)")
    parser.add_argument("--window-class", help="Capture window by class name")
    parser.add_argument("--window-id", type=int, help="Capture specific window ID")
    parser.add_argument("--screen", type=int, help="Capture specific screen number (0-indexed)")
    parser.add_argument("--list-windows", action="store_true", help="List all visible windows")
    
    args = parser.parse_args()
    
    # Set display
    os.environ['DISPLAY'] = args.display
    
    # Handle list-windows first
    if args.list_windows:
        windows = list_windows()
        result = {
            "success": True,
            "action": "list_windows",
            "windows": windows,
            "count": len(windows)
        }
        print(json.dumps(result, indent=2))
        return 0
    
    screen_width, screen_height = get_screen_size()
    
    # Determine screenshot mode
    window_id = None
    window_geometry = None
    
    if args.window_id:
        window_id = args.window_id
    elif args.window:
        windows = find_window_by_name(args.window)
        if not windows:
            print(json.dumps({"success": False, "error": f"No window found matching: {args.window}"}))
            return 1
        window_id = windows[0]  # Take first match
    elif args.window_class:
        windows = find_window_by_class(args.window_class)
        if not windows:
            print(json.dumps({"success": False, "error": f"No window found with class: {args.window_class}"}))
            return 1
        window_id = windows[0]  # Take first match
    
    # Take screenshot based on mode
    if window_id:
        window_geometry = get_window_geometry(window_id)
        screenshot_path = take_screenshot_window(window_id)
    elif args.screen is not None:
        screenshot_path = take_screenshot_screen(args.screen)
    else:
        screenshot_path = take_screenshot()
    
    if args.screenshot:
        result = {
            "success": True,
            "screenshot": str(screenshot_path),
            "screen_size": {"width": screen_width, "height": screen_height}
        }
        if window_id:
            result["window_id"] = window_id
            result["window_geometry"] = window_geometry
            result["note"] = "Coordinates are relative to window, not screen"
        if args.screen is not None:
            result["screen"] = args.screen
        print(json.dumps(result, indent=2))
        return 0
    
    if args.coords:
        x, y = args.coords
        # If window mode, coordinates are relative to window - translate to screen
        screen_x, screen_y = x, y
        if window_id and window_geometry:
            screen_x = x + window_geometry.get("X", 0)
            screen_y = y + window_geometry.get("Y", 0)
        
        clicked = False
        if not args.no_click:
            clicked = click_at(screen_x, screen_y, args.click_type)
            if args.type_text:
                time.sleep(0.1)
                type_text(args.type_text)
            if args.key:
                time.sleep(0.1)
                press_key(args.key)
        
        result = {
            "success": True,
            "action": "click" if clicked else "locate",
            "x": x,
            "y": y,
            "click_type": args.click_type,
            "screenshot": str(screenshot_path)
        }
        if window_id:
            result["window_id"] = window_id
            result["screen_coords"] = {"x": screen_x, "y": screen_y}
        print(json.dumps(result, indent=2))
        return 0
    
    if args.template:
        match = find_template(screenshot_path, args.template, args.confidence)
        
        if match:
            x, y, conf = match
            clicked = False
            if not args.no_click:
                clicked = click_at(x, y, args.click_type)
                if args.type_text:
                    time.sleep(0.1)
                    type_text(args.type_text)
                if args.key:
                    time.sleep(0.1)
                    press_key(args.key)
            
            result = {
                "success": True,
                "action": "click" if clicked else "locate",
                "x": x,
                "y": y,
                "confidence": round(conf, 3),
                "template": args.template,
                "screenshot": str(screenshot_path)
            }
        else:
            result = {
                "success": False,
                "error": f"Template not found: {args.template}",
                "screenshot": str(screenshot_path)
            }
        
        print(json.dumps(result, indent=2))
        return 0 if match else 1
    
    if args.description:
        # Vision mode - output for AI analysis
        result = {
            "action": "vision_find",
            "description": args.description,
            "screenshot": str(screenshot_path),
            "screen_size": {"width": screen_width, "height": screen_height},
            "instructions": "Analyze the screenshot and return the center coordinates of the described element as JSON: {\"x\": N, \"y\": N}"
        }
        print(json.dumps(result, indent=2))
        return 0
    
    # No action - show help
    result = {
        "success": True,
        "screenshot": str(screenshot_path),
        "screen_size": {"width": screen_width, "height": screen_height},
        "usage": {
            "--screenshot, -s": "Take screenshot only",
            "--coords X Y, -c X Y": "Click at coordinates",
            "--template IMG, -t IMG": "Find and click template image",
            "DESCRIPTION": "Output for AI vision analysis"
        }
    }
    print(json.dumps(result, indent=2))
    return 0

if __name__ == "__main__":
    sys.exit(main())
