#!/bin/bash
# Screenshot Tool for Claude Code
# Enable Claude to see your browser/dashboard state directly
# https://github.com/BlakeFelix/claude_code_screenshot_tool

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
SCREENSHOT_PATH="${SCREENSHOT_DIR}/dashboard_${TIMESTAMP}.png"
TEMP_PATH="${SCREENSHOT_DIR}/temp_${TIMESTAMP}.png"

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Parse command line arguments
MODE="full"
WINDOW_NAME=""
ZOOM_FACTOR=""
SELECT_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--window)
            MODE="window"
            WINDOW_NAME="$2"
            shift 2
            ;;
        -s|--select)
            SELECT_MODE=true
            shift
            ;;
        -z|--zoom)
            ZOOM_FACTOR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Screenshot Tool for Claude Code"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -w, --window NAME    Capture specific window by name"
            echo "  -s, --select         Interactive region selection"
            echo "  -z, --zoom FACTOR    Zoom/upscale image (e.g., 2 for 2x)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                         # Full screen capture"
            echo "  $0 --window Firefox        # Capture Firefox window"
            echo "  $0 --select                # Draw box around region"
            echo "  $0 --zoom 2                # Full screen at 2x zoom"
            echo "  $0 --select --zoom 2       # Select region and zoom 2x"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate zoom factor if provided
if [ -n "$ZOOM_FACTOR" ]; then
    if ! [[ "$ZOOM_FACTOR" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "❌ Error: --zoom requires a numeric value (e.g., 2 or 1.5)"
        exit 1
    fi
fi

# Validate window mode
if [ "$MODE" = "window" ] && [ -z "$WINDOW_NAME" ]; then
    echo "❌ Error: --window requires a window name"
    echo "Usage: $0 --window 'Window Name'"
    exit 1
fi

# Determine output path (use temp if we need to zoom)
if [ -n "$ZOOM_FACTOR" ]; then
    CAPTURE_PATH="$TEMP_PATH"
else
    CAPTURE_PATH="$SCREENSHOT_PATH"
fi

# Capture based on mode
if [ "$SELECT_MODE" = true ]; then
    echo "📸 Draw a box around the region you want to capture..."
    scrot -s "$CAPTURE_PATH" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "❌ Selection failed. Make sure scrot is installed:"
        echo "  sudo apt-get install scrot"
        exit 1
    fi

elif [ "$MODE" = "window" ]; then
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
        import -window $WINDOW_ID "$CAPTURE_PATH" 2>/dev/null
    else
        # Fallback to scrot with window ID
        scrot -u -d 0.1 "$CAPTURE_PATH" 2>/dev/null
    fi
else
    # Full screen capture
    scrot "$CAPTURE_PATH"
fi

# Check if capture succeeded
if [ ! -f "$CAPTURE_PATH" ]; then
    echo "❌ Screenshot failed"
    echo "Make sure required tools are installed:"
    echo "  sudo apt-get install scrot xdotool imagemagick"
    exit 1
fi

# Apply zoom if requested
if [ -n "$ZOOM_FACTOR" ]; then
    if ! command -v convert &> /dev/null; then
        echo "⚠️  Warning: imagemagick not found, skipping zoom"
        echo "  Install with: sudo apt-get install imagemagick"
        mv "$CAPTURE_PATH" "$SCREENSHOT_PATH"
    else
        echo "🔍 Zooming ${ZOOM_FACTOR}x..."
        ZOOM_PERCENT=$(echo "$ZOOM_FACTOR * 100" | bc)
        convert "$CAPTURE_PATH" -resize ${ZOOM_PERCENT}% "$SCREENSHOT_PATH" 2>/dev/null

        if [ $? -eq 0 ]; then
            rm "$CAPTURE_PATH"
        else
            echo "⚠️  Warning: zoom failed, keeping original"
            mv "$CAPTURE_PATH" "$SCREENSHOT_PATH"
        fi
    fi
fi

# Report success
echo "✅ Screenshot saved: $SCREENSHOT_PATH"
echo "File size: $(du -h "$SCREENSHOT_PATH" | cut -f1)"
if [ -n "$ZOOM_FACTOR" ]; then
    echo "Zoom level: ${ZOOM_FACTOR}x"
fi
echo ""
echo "To view, Claude can read: $SCREENSHOT_PATH"
