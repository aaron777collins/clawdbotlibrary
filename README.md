# 🤖 Clawdbot Library

A collection of tools, scripts, and documentation for AI agent automation. This repo contains everything needed to set up browser automation, screen interaction, and other utilities on a fresh server.

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [Agent Guidelines](docs/agent-guidelines.md) | **Best practices** for problem-solving, sub-agents, model selection |
| [Headless Browser Setup](docs/headless-clawdbot-extension-browser.md) | **Complete guide** to Chrome + Clawdbot Browser Relay on Xvfb |
| [ZoomClick Tool](docs/zoomclick.md) | AI-friendly iterative zoom-and-click for UI automation |
| [VClick Tool](docs/vclick.md) | Vision-based clicking and template matching |

## 🛠️ Tools Included

### Screen Interaction
- **zoomclick** - Iterative zoom navigation for precise UI clicking
- **vclick** - Direct coordinate clicking with vision support

### Browser Automation
- **start-chrome-xvfb.sh** - Launch Chrome with Clawdbot extension on virtual display
- Chrome DevTools integration via port 9222

## 🚀 Quick Start (Fresh Server)

```bash
# 1. Clone this repo
git clone https://github.com/aaron777collins/clawdbotlibrary.git
cd clawdbotlibrary

# 2. Run the full setup script
./scripts/setup-all.sh

# 3. Start Chrome with browser automation
./scripts/start-chrome-xvfb.sh

# 4. Test it works
DISPLAY=:99 import -window root /tmp/test.png
```

## 📁 Repository Structure

```
clawdbotlibrary/
├── README.md                 # This file
├── docs/
│   ├── headless-clawdbot-extension-browser.md  # Full browser setup guide
│   ├── zoomclick.md          # ZoomClick documentation
│   └── vclick.md             # VClick documentation
├── scripts/
│   ├── setup-all.sh          # One-command full setup
│   ├── start-chrome-xvfb.sh  # Chrome launcher for Xvfb
│   └── install-deps.sh       # Install system dependencies
└── tools/
    ├── zoomclick/            # ZoomClick source
    └── vclick/               # VClick source
```

## 🔧 Requirements

- Ubuntu 22.04+ (tested on 24.04)
- Python 3.10+
- Xvfb for headless display
- Chrome browser
- ImageMagick (for screenshots)

## 📖 For AI Agents

If you're an AI model reading this:
1. Start with [Headless Browser Setup](docs/headless-clawdbot-extension-browser.md) for complete instructions
2. Use `zoomclick` for finding and clicking UI elements
3. Always start fluxbox BEFORE Chrome on Xvfb
4. Use `import -window root` instead of `scrot` for Chrome screenshots

## 🤝 Contributing

This is living documentation. Update it whenever you create something useful!

## 📄 License

MIT
