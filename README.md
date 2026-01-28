# Clawdbot Library

> **A living library of tools, scripts, and documentation for Clawdbot automation.**

This repository contains everything you need to set up and extend Clawdbot with powerful automation capabilities. Each component is documented with step-by-step guides that even simpler AI models can follow.

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Headless Browser Setup](docs/headlessclawdbotextensionbrowser.md) | Complete guide to running Chrome headlessly with Clawdbot Browser Relay |

## 🛠️ Tools

### vclick - Vision Click Tool

A vision-based clicking tool that uses screenshots and coordinates for precise mouse control.

**Features:**
- Take screenshots (full screen or specific window)
- Click at specific coordinates
- Template matching (find image on screen, click it)
- Keyboard input after clicking

**Quick Start:**
```bash
cd tools/vclick
python3 vclick.py --screenshot                    # Take screenshot
python3 vclick.py --coords 500 300                # Click at position
python3 vclick.py --template button.png           # Find and click template
```

[Full documentation →](tools/vclick/README.md)

---

### zoomclick - Iterative Zoom-and-Click Tool

An AI-friendly tool for precise UI clicking through iterative zooming. Instead of guessing pixel coordinates, progressively zoom into quadrants until your target is big and centered, then save it as a reusable template.

**Features:**
- Interactive zooming to find small UI elements
- Save targets as named templates
- Template matching with confidence scoring
- Automatic fallback to saved coordinates

**Quick Start:**
```bash
cd tools/zoomclick
python3 zoomclick.py --start                      # Start session
python3 zoomclick.py --zoom top-right             # Zoom into quadrant
python3 zoomclick.py --save "my_button"           # Save as template
python3 zoomclick.py --click "my_button"          # Click saved template
```

[Full documentation →](tools/zoomclick/README.md)

---

## 📜 Scripts

### start-chrome-automation.sh

Robust startup script for headless Chrome with Clawdbot Browser Relay.

**Features:**
- Starts Xvfb, Fluxbox, and Chrome with proper daemonization
- Auto-fixes Chrome crash recovery prompts
- Clicks Browser Relay extension via template matching
- Survives SSH disconnection and reboots

**Usage:**
```bash
/home/ubuntu/start-chrome-automation.sh
```

[Full documentation →](scripts/README.md)

---

## 🚀 Quick Setup

### For Headless Browser Automation

1. **Read the full guide:** [docs/headlessclawdbotextensionbrowser.md](docs/headlessclawdbotextensionbrowser.md)

2. **TL;DR version:**
   ```bash
   # Install dependencies
   sudo apt install -y xvfb fluxbox scrot imagemagick python3-opencv python3-pip xdotool bc
   pip3 install pyautogui pillow
   
   # Install Chrome
   wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
   sudo dpkg -i google-chrome-stable_current_amd64.deb
   sudo apt --fix-broken install -y
   
   # Clone this repo
   git clone https://github.com/aaron777collins/clawdbotlibrary.git
   cd clawdbotlibrary
   
   # Copy tools to home directory
   cp -r tools/vclick ~/vclick
   cp -r tools/zoomclick ~/zoomclick
   
   # Copy and run startup script
   cp scripts/start-chrome-automation.sh ~/
   chmod +x ~/start-chrome-automation.sh
   ~/start-chrome-automation.sh
   ```

3. **Verify it works:**
   ```bash
   browser action=tabs profile=chrome
   ```

---

## 📁 Repository Structure

```
clawdbotlibrary/
├── README.md                    # This file
├── docs/
│   └── headlessclawdbotextensionbrowser.md   # Complete browser setup guide
├── tools/
│   ├── vclick/                  # Vision click tool
│   │   ├── README.md
│   │   └── vclick.py
│   └── zoomclick/               # Zoom and click tool
│       ├── README.md
│       └── zoomclick.py
└── scripts/
    ├── README.md
    └── start-chrome-automation.sh   # Browser startup script
```

---

## 🔄 Contributing

This is a living repository! When you create something cool:

1. Add your tool/script to the appropriate directory
2. Write documentation (README or guide in `docs/`)
3. Update this README with a summary
4. Commit and push

```bash
git add .
git commit -m "Add [your feature]"
git push
```

---

## 📝 Changelog

### 2026-01-27
- Initial release
- Added headless browser setup guide
- Added vclick and zoomclick tools
- Added start-chrome-automation.sh script

---

## 📄 License

MIT License - Feel free to use, modify, and share.

---

## 🤝 Credits

- **vclick**: [github.com/aaron777collins/vclick](https://github.com/aaron777collins/vclick)
- **zoomclick**: [github.com/aaron777collins/EnhanceAndClick](https://github.com/aaron777collins/EnhanceAndClick)
- **Clawdbot**: [github.com/clawdbot/clawdbot](https://github.com/clawdbot/clawdbot)
