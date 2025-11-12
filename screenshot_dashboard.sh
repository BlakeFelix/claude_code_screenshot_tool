#!/bin/bash
# Screenshot Tool for Claude Code
# Enable Claude to see your browser/dashboard state directly
# https://github.com/YOUR_USERNAME/screenshot-tool-claude

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
SCREENSHOT_PATH="${SCREENSHOT_DIR}/dashboard_${TIMESTAMP}.png"

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Parse command line arguments
MODE="full"
WINDOW_NAME=""

if [ "$1" = "--window" ] || [ "$1" = "-w" ]; then
    MODE="window"
    WINDOW_NAME="$2"
    if [ -z "$WINDOW_NAME" ]; then
        echo "❌ Error: --window requires a window name"
        echo "Usage: $0 --window 'Window Name'"
        exit 1
    fi
fi

# Capture based on mode
if [ "$MODE" = "window" ]; then
    # Find window by name pattern
    WINDOW_ID=$(xdotool search --name "$WINDOW_NAME" 2>/dev/null | head -1)

    if [ -z "$WINDOW_ID" ]; then
        echo "❌ No window found matching: '$WINDOW_NAME'"
        echo "Available windows:"
        wmctrl -l 2>/dev/null || xdotool search --name "." getwindowname 2>/dev/null || echo "  (install wmctrl or xdotool to list windows)"
        exit 1
    fi

    # Get window name for confirmation
    ACTUAL_NAME=$(xdotool getwindowname $WINDOW_ID 2>/dev/null)
    echo "📸 Capturing window: $ACTUAL_NAME (ID: $WINDOW_ID)"

    # Try imagemagick's import first (cleaner for single windows)
    if command -v import &> /dev/null; then
        import -window $WINDOW_ID "$SCREENSHOT_PATH" 2>/dev/null
    else
        # Fallback to scrot with window ID
        scrot -u -d 0.1 "$SCREENSHOT_PATH" 2>/dev/null
    fi
else
    # Full screen capture
    scrot "$SCREENSHOT_PATH"
fi

if [ -f "$SCREENSHOT_PATH" ]; then
    echo "✅ Screenshot saved: $SCREENSHOT_PATH"
    echo "File size: $(du -h "$SCREENSHOT_PATH" | cut -f1)"
    echo ""
    echo "To view, Claude can read: $SCREENSHOT_PATH"
else
    echo "❌ Screenshot failed"
    echo "Make sure required tools are installed:"
    echo "  sudo apt-get install scrot xdotool imagemagick"
    exit 1
fi
