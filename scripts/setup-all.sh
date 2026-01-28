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
mkdir -p ~/tools
mkdir -p /tmp/zoomclick

# 3. Install ZoomClick tool
echo "Installing ZoomClick..."
if [ -d "$REPO_DIR/tools/zoomclick" ]; then
    # Copy to ~/tools/zoomclick
    cp -r "$REPO_DIR/tools/zoomclick" ~/tools/
    chmod +x ~/tools/zoomclick/zoomclick.py
    # Create symlink in /usr/local/bin
    sudo ln -sf ~/tools/zoomclick/zoomclick.py /usr/local/bin/zoomclick
    echo "  ✓ ZoomClick installed to ~/tools/zoomclick"
    echo "  ✓ Symlink created: /usr/local/bin/zoomclick"
else
    echo "  ⚠ ZoomClick source not found in tools/"
    echo "  → Clone from: https://github.com/aaron777collins/EnhanceAndClick"
fi

# 4. Install VClick tool
echo "Installing VClick..."
if [ -d "$REPO_DIR/tools/vclick" ]; then
    # Copy to ~/tools/vclick
    cp -r "$REPO_DIR/tools/vclick" ~/tools/
    chmod +x ~/tools/vclick/vclick.py
    # Create symlink in /usr/local/bin
    sudo ln -sf ~/tools/vclick/vclick.py /usr/local/bin/vclick
    echo "  ✓ VClick installed to ~/tools/vclick"
    echo "  ✓ Symlink created: /usr/local/bin/vclick"
else
    echo "  ⚠ VClick source not found in tools/"
    echo "  → Clone from: https://github.com/aaron777collins/vclick"
fi

# 5. Install startup script
echo "Installing startup script..."
cp "$SCRIPT_DIR/start-chrome-automation.sh" ~/start-chrome-automation.sh
chmod +x ~/start-chrome-automation.sh
echo "  ✓ Startup script at ~/start-chrome-automation.sh"

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
echo "  ~/start-chrome-automation.sh              # Start Chrome on display :99"
echo "  DISPLAY=:99 zoomclick --start       # Start interactive zoom session"
echo "  DISPLAY=:99 import -window root /tmp/test.png  # Take screenshot"
echo ""
echo "See docs/headless-browser-setup.md for full guide"
