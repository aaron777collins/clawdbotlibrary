#!/bin/bash
# Install all system dependencies for Chrome automation
# Run as root: sudo ./install-deps.sh

set -e

echo "=== Installing Chrome Automation Dependencies ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

# Update package lists
echo "[1/6] Updating package lists..."
apt update

# Install core packages
echo "[2/6] Installing core packages..."
apt install -y \
    xvfb \
    fluxbox \
    scrot \
    imagemagick \
    xdotool \
    x11-utils \
    curl \
    wget \
    bc \
    git

# Install Python and pip
echo "[3/6] Installing Python..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv

# Install Python packages globally
echo "[4/6] Installing Python packages..."
pip3 install --break-system-packages \
    pyautogui \
    opencv-python \
    pillow \
    numpy

# Install Google Chrome
echo "[5/6] Installing Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    # Add Chrome's GPG key
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - 2>/dev/null || \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    
    # Add Chrome's repository
    if [ -f /usr/share/keyrings/google-chrome.gpg ]; then
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    else
        echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
    fi
    
    apt update
    apt install -y google-chrome-stable
    echo "  ✓ Chrome installed"
else
    echo "  ✓ Chrome already installed: $(google-chrome --version)"
fi

# Verify installations
echo ""
echo "[6/6] Verifying installations..."
echo ""

MISSING=""

check_cmd() {
    if command -v "$1" &> /dev/null; then
        echo "  ✓ $1"
    else
        echo "  ✗ $1 NOT FOUND"
        MISSING="$MISSING $1"
    fi
}

check_cmd Xvfb
check_cmd fluxbox
check_cmd scrot
check_cmd convert
check_cmd xdotool
check_cmd python3
check_cmd google-chrome
check_cmd bc
check_cmd git

echo ""

# Check Python packages
echo "Python packages:"
python3 -c "import pyautogui; print('  ✓ pyautogui', pyautogui.__version__)" 2>/dev/null || echo "  ✗ pyautogui NOT FOUND"
python3 -c "import cv2; print('  ✓ opencv', cv2.__version__)" 2>/dev/null || echo "  ✗ opencv NOT FOUND"
python3 -c "import PIL; print('  ✓ pillow', PIL.__version__)" 2>/dev/null || echo "  ✗ pillow NOT FOUND"
python3 -c "import numpy; print('  ✓ numpy', numpy.__version__)" 2>/dev/null || echo "  ✗ numpy NOT FOUND"

echo ""

if [ -n "$MISSING" ]; then
    echo "⚠ Some packages failed to install:$MISSING"
    exit 1
else
    echo "=== All dependencies installed successfully! ==="
fi
