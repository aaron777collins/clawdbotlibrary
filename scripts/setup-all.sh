#!/bin/bash
# Complete setup for Clawdbot browser automation
# Makes a fresh server ready for headless Chrome automation
#
# Usage:
#   sudo ./setup-all.sh          # Full setup (recommended)
#   ./setup-all.sh --no-root     # Skip system deps (if already installed)
#
# GitHub: https://github.com/aaron777collins/clawdbotlibrary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$HOME/tools"
SKIP_ROOT=false

# Parse args
for arg in "$@"; do
    case $arg in
        --no-root) SKIP_ROOT=true ;;
    esac
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Clawdbot Library - Complete Setup                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Repository: $REPO_DIR"
echo "Tools will be installed to: $TOOLS_DIR"
echo ""

# ============================================================
# Step 1: System Dependencies
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 1: System Dependencies                                │"
echo "└────────────────────────────────────────────────────────────┘"

if [ "$SKIP_ROOT" = true ]; then
    echo "Skipping system dependencies (--no-root flag)"
elif [ "$EUID" -eq 0 ]; then
    echo "Running as root - installing system dependencies..."
    "$SCRIPT_DIR/install-deps.sh"
else
    echo "Not running as root - skipping system dependencies"
    echo "Run 'sudo ./scripts/install-deps.sh' separately if needed"
fi
echo ""

# ============================================================
# Step 2: Create Directory Structure
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 2: Creating Directories                               │"
echo "└────────────────────────────────────────────────────────────┘"

mkdir -p "$TOOLS_DIR"
mkdir -p "$HOME/.chrome-automation"
mkdir -p "$HOME/.zoomclick/templates"
mkdir -p /tmp/zoomclick 2>/dev/null || true

echo "  ✓ $TOOLS_DIR"
echo "  ✓ $HOME/.chrome-automation"
echo "  ✓ $HOME/.zoomclick/templates"
echo ""

# ============================================================
# Step 3: Install vclick
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 3: Installing vclick                                  │"
echo "└────────────────────────────────────────────────────────────┘"
echo "  GitHub: https://github.com/aaron777collins/vclick"

if [ -d "$TOOLS_DIR/vclick/.git" ]; then
    echo "  Updating existing installation..."
    cd "$TOOLS_DIR/vclick"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    echo "  Cloning repository..."
    rm -rf "$TOOLS_DIR/vclick"
    git clone https://github.com/aaron777collins/vclick.git "$TOOLS_DIR/vclick"
fi

chmod +x "$TOOLS_DIR/vclick/vclick.py"

# Create symlink (needs sudo if /usr/local/bin not writable)
if [ -w /usr/local/bin ] || [ "$EUID" -eq 0 ]; then
    ln -sf "$TOOLS_DIR/vclick/vclick.py" /usr/local/bin/vclick
    echo "  ✓ Installed to $TOOLS_DIR/vclick"
    echo "  ✓ Symlink: /usr/local/bin/vclick"
else
    echo "  ✓ Installed to $TOOLS_DIR/vclick"
    echo "  ⚠ Run 'sudo ln -sf $TOOLS_DIR/vclick/vclick.py /usr/local/bin/vclick' for global access"
fi
echo ""

# ============================================================
# Step 4: Install zoomclick
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 4: Installing zoomclick                               │"
echo "└────────────────────────────────────────────────────────────┘"
echo "  GitHub: https://github.com/aaron777collins/EnhanceAndClick"

if [ -d "$TOOLS_DIR/zoomclick/.git" ]; then
    echo "  Updating existing installation..."
    cd "$TOOLS_DIR/zoomclick"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    echo "  Cloning repository..."
    rm -rf "$TOOLS_DIR/zoomclick"
    git clone https://github.com/aaron777collins/EnhanceAndClick.git "$TOOLS_DIR/zoomclick"
fi

chmod +x "$TOOLS_DIR/zoomclick/zoomclick.py"

# Create symlink
if [ -w /usr/local/bin ] || [ "$EUID" -eq 0 ]; then
    ln -sf "$TOOLS_DIR/zoomclick/zoomclick.py" /usr/local/bin/zoomclick
    echo "  ✓ Installed to $TOOLS_DIR/zoomclick"
    echo "  ✓ Symlink: /usr/local/bin/zoomclick"
else
    echo "  ✓ Installed to $TOOLS_DIR/zoomclick"
    echo "  ⚠ Run 'sudo ln -sf $TOOLS_DIR/zoomclick/zoomclick.py /usr/local/bin/zoomclick' for global access"
fi
echo ""

# ============================================================
# Step 5: Install Startup Script
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 5: Installing Startup Script                          │"
echo "└────────────────────────────────────────────────────────────┘"

cp "$SCRIPT_DIR/start-chrome-automation.sh" "$HOME/start-chrome-automation.sh"
chmod +x "$HOME/start-chrome-automation.sh"
echo "  ✓ $HOME/start-chrome-automation.sh"
echo ""

# ============================================================
# Step 6: Setup Xvfb Service (if root)
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 6: Xvfb Systemd Service                               │"
echo "└────────────────────────────────────────────────────────────┘"

if [ "$EUID" -eq 0 ]; then
    cat > /etc/systemd/system/xvfb.service << 'EOF'
[Unit]
Description=X Virtual Frame Buffer
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable xvfb
    systemctl start xvfb 2>/dev/null || systemctl restart xvfb
    echo "  ✓ Xvfb service enabled and started"
else
    echo "  ⚠ Not running as root - skipping systemd service"
    echo "  → Start Xvfb manually: Xvfb :99 -screen 0 1920x1080x24 &"
fi
echo ""

# ============================================================
# Step 7: Setup Crontab (optional)
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 7: Auto-start on Reboot (crontab)                     │"
echo "└────────────────────────────────────────────────────────────┘"

# Check if already in crontab
if crontab -l 2>/dev/null | grep -q "start-chrome-automation"; then
    echo "  ✓ Already configured in crontab"
else
    echo "  Adding to crontab..."
    (crontab -l 2>/dev/null | grep -v "start-chrome-automation"; echo "@reboot $HOME/start-chrome-automation.sh >> /tmp/chrome-automation.log 2>&1") | crontab -
    echo "  ✓ Added @reboot entry to crontab"
fi
echo ""

# ============================================================
# Step 8: Verification
# ============================================================
echo "┌────────────────────────────────────────────────────────────┐"
echo "│ Step 8: Verification                                       │"
echo "└────────────────────────────────────────────────────────────┘"

echo "Checking installed components..."
echo ""

# Check commands
check_installed() {
    if command -v "$1" &> /dev/null; then
        echo "  ✓ $1"
        return 0
    else
        echo "  ✗ $1 - NOT FOUND"
        return 1
    fi
}

ERRORS=0

check_installed Xvfb || ((ERRORS++))
check_installed fluxbox || ((ERRORS++))
check_installed scrot || ((ERRORS++))
check_installed google-chrome || ((ERRORS++))
check_installed python3 || ((ERRORS++))

# Check tools
if [ -f "$TOOLS_DIR/vclick/vclick.py" ]; then
    echo "  ✓ vclick"
else
    echo "  ✗ vclick - NOT FOUND"
    ((ERRORS++))
fi

if [ -f "$TOOLS_DIR/zoomclick/zoomclick.py" ]; then
    echo "  ✓ zoomclick"
else
    echo "  ✗ zoomclick - NOT FOUND"
    ((ERRORS++))
fi

# Check startup script
if [ -f "$HOME/start-chrome-automation.sh" ]; then
    echo "  ✓ start-chrome-automation.sh"
else
    echo "  ✗ start-chrome-automation.sh - NOT FOUND"
    ((ERRORS++))
fi

echo ""

# ============================================================
# Done!
# ============================================================
echo "╔════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ]; then
    echo "║  ✓ Setup Complete! All components installed.              ║"
else
    echo "║  ⚠ Setup Complete with $ERRORS error(s). Check above.          ║"
fi
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Quick Start:"
echo "  1. Start Chrome:  \$HOME/start-chrome-automation.sh"
echo "  2. Screenshot:    DISPLAY=:99 scrot /tmp/test.png"
echo "  3. Zoom & click:  DISPLAY=:99 zoomclick --start"
echo ""
echo "Documentation: $REPO_DIR/docs/headless-browser-setup.md"
echo ""
