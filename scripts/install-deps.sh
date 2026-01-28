#!/bin/bash
# Install all system dependencies for Clawdbot browser automation
# Run with: sudo ./install-deps.sh

set -e

echo "=== Installing Clawdbot Library Dependencies ==="

# Update package lists
echo "Updating packages..."
apt update

# Install Xvfb (virtual display)
echo "Installing Xvfb..."
apt install -y xvfb

# Install Fluxbox (window manager - REQUIRED!)
echo "Installing Fluxbox..."
apt install -y fluxbox

# Install ImageMagick (screenshots)
echo "Installing ImageMagick..."
apt install -y imagemagick

# Install xdotool (window/keyboard control)
echo "Installing xdotool..."
apt install -y xdotool

# Install Python dependencies
echo "Installing Python packages..."
apt install -y python3-pip python3-opencv

# Install PyAutoGUI
pip3 install --break-system-packages pyautogui opencv-python numpy 2>/dev/null || \
pip3 install pyautogui opencv-python numpy

# Install Chrome if not present
if ! command -v google-chrome &> /dev/null; then
    echo "Installing Chrome..."
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
    apt update
    apt install -y google-chrome-stable
else
    echo "Chrome already installed"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "  1. Start Xvfb:  Xvfb :99 -screen 0 1920x1080x24 &"
echo "  2. Run setup:   ./scripts/setup-all.sh"
