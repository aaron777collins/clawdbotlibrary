#!/bin/bash
# Complete setup for Clawdbot browser automation
# Run from the clawdbotlibrary directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Clawdbot Library Setup ==="
echo "Repository: $REPO_DIR"
echo ""

# 1. Install dependencies if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Running as root - installing system dependencies..."
    "$SCRIPT_DIR/install-deps.sh"
else
    echo "Not running as root - skipping system dependencies"
    echo "Run 'sudo ./scripts/install-deps.sh' separately if needed"
fi

# 2. Create directories
echo ""
echo "Creating directories..."
mkdir -p ~/.chrome-automation
mkdir -p ~/.zoomclick/templates
mkdir -p /tmp/zoomclick

# 3. Install ZoomClick tool
echo "Installing ZoomClick..."
if [ -f "$REPO_DIR/tools/zoomclick/zoomclick.py" ]; then
    sudo cp "$REPO_DIR/tools/zoomclick/zoomclick.py" /usr/local/bin/zoomclick
    sudo cp "$REPO_DIR/tools/zoomclick/helpers.py" /usr/local/bin/zoomclick_helpers.py 2>/dev/null || true
    sudo chmod +x /usr/local/bin/zoomclick
    echo "  ✓ ZoomClick installed to /usr/local/bin/zoomclick"
else
    echo "  ⚠ ZoomClick source not found in tools/"
fi

# 4. Install VClick tool
echo "Installing VClick..."
if [ -f "$REPO_DIR/tools/vclick/vclick.py" ]; then
    sudo cp "$REPO_DIR/tools/vclick/vclick.py" /usr/local/bin/vclick
    sudo chmod +x /usr/local/bin/vclick
    echo "  ✓ VClick installed to /usr/local/bin/vclick"
else
    echo "  ⚠ VClick source not found in tools/"
fi

# 5. Install startup script
echo "Installing startup script..."
cp "$SCRIPT_DIR/start-chrome-xvfb.sh" ~/start-chrome-xvfb.sh
chmod +x ~/start-chrome-xvfb.sh
echo "  ✓ Startup script at ~/start-chrome-xvfb.sh"

# 6. Setup Xvfb systemd service (if root)
if [ "$EUID" -eq 0 ]; then
    echo "Setting up Xvfb systemd service..."
    cat > /etc/systemd/system/xvfb.service << 'EOF'
[Unit]
Description=X Virtual Frame Buffer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable xvfb
    systemctl start xvfb
    echo "  ✓ Xvfb service enabled and started"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Quick start:"
echo "  ~/start-chrome-xvfb.sh              # Start Chrome on display :99"
echo "  DISPLAY=:99 zoomclick --start       # Start interactive zoom session"
echo "  DISPLAY=:99 import -window root /tmp/test.png  # Take screenshot"
echo ""
echo "See docs/headless-clawdbot-extension-browser.md for full guide"
