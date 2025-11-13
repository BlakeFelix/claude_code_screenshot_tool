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
ZONE=""
REGION=""

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
        --zone)
            ZONE="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
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
            echo "  --zone ZONE          Capture pre-defined zone (autonomous)"
            echo "  --region X,Y,W,H     Capture custom region (pixels)"
            echo "  -z, --zoom FACTOR    Zoom/upscale image (e.g., 2 for 2x)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Available zones:"
            echo "  top-left, top-right, bottom-left, bottom-right"
            echo "  center, top, middle, bottom, left, right"
            echo ""
            echo "Examples:"
            echo "  $0                              # Full screen capture"
            echo "  $0 --window Firefox             # Capture Firefox window"
            echo "  $0 --zone bottom --zoom 2       # Bottom third, zoomed 2x"
            echo "  $0 --zone center --zoom 3       # Center area, magnified 3x"
            echo "  $0 --region 100,100,800,600     # Custom 800x600 region"
            echo "  $0 --select                     # Draw box around region"
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

# Determine output path (use temp if we need to post-process)
NEEDS_PROCESSING=false
if [ -n "$ZOOM_FACTOR" ] || [ -n "$ZONE" ] || [ -n "$REGION" ]; then
    NEEDS_PROCESSING=true
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

# Post-processing (crop zones/regions, then zoom)
if [ "$NEEDS_PROCESSING" = true ]; then
    if ! command -v convert &> /dev/null; then
        echo "⚠️  Warning: imagemagick not found, skipping post-processing"
        echo "  Install with: sudo apt-get install imagemagick"
        mv "$CAPTURE_PATH" "$SCREENSHOT_PATH"
    else
        WORK_FILE="$CAPTURE_PATH"
        CROP_FILE="${SCREENSHOT_DIR}/crop_${TIMESTAMP}.png"

        # Function to calculate crop geometry for a single zone
        calculate_zone_geometry() {
            local ZONE_NAME=$1
            local CUR_WIDTH=$2
            local CUR_HEIGHT=$3

            case "$ZONE_NAME" in
                        top-left)
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT}+0+0"
                            WIDTH=$((WIDTH / 2))
                            HEIGHT=$((HEIGHT / 2))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT}+0+0"
                            ;;
                        top-right)
                            WIDTH_HALF=$((WIDTH / 2))
                            HEIGHT=$((HEIGHT / 2))
                            CROP_GEOMETRY="${WIDTH_HALF}x${HEIGHT}+${WIDTH_HALF}+0"
                            ;;
                        bottom-left)
                            WIDTH=$((WIDTH / 2))
                            HEIGHT_HALF=$((HEIGHT / 2))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT_HALF}+0+${HEIGHT_HALF}"
                            ;;
                        bottom-right)
                            WIDTH_HALF=$((WIDTH / 2))
                            HEIGHT_HALF=$((HEIGHT / 2))
                            CROP_GEOMETRY="${WIDTH_HALF}x${HEIGHT_HALF}+${WIDTH_HALF}+${HEIGHT_HALF}"
                            ;;
                        center)
                            WIDTH_QUARTER=$((WIDTH / 4))
                            HEIGHT_QUARTER=$((HEIGHT / 4))
                            WIDTH_HALF=$((WIDTH / 2))
                            HEIGHT_HALF=$((HEIGHT / 2))
                            CROP_GEOMETRY="${WIDTH_HALF}x${HEIGHT_HALF}+${WIDTH_QUARTER}+${HEIGHT_QUARTER}"
                            ;;
                        top)
                            HEIGHT_THIRD=$((HEIGHT / 3))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT_THIRD}+0+0"
                            ;;
                        middle)
                            HEIGHT_THIRD=$((HEIGHT / 3))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT_THIRD}+0+${HEIGHT_THIRD}"
                            ;;
                        bottom)
                            HEIGHT_THIRD=$((HEIGHT / 3))
                            OFFSET=$((HEIGHT_THIRD * 2))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT_THIRD}+0+${OFFSET}"
                            ;;
                        left)
                            WIDTH=$((WIDTH / 2))
                            CROP_GEOMETRY="${WIDTH}x${HEIGHT}+0+0"
                            ;;
                        right)
                            WIDTH_HALF=$((WIDTH / 2))
                            CROP_GEOMETRY="${WIDTH_HALF}x${HEIGHT}+${WIDTH_HALF}+0"
                            ;;
                        *)
                            echo "❌ Unknown zone: $ZONE"
                            echo "Available: top-left, top-right, bottom-left, bottom-right, center, top, middle, bottom, left, right"
                            mv "$WORK_FILE" "$SCREENSHOT_PATH"
                            exit 1
                            ;;
                    esac
                elif [ -n "$REGION" ]; then
                    echo "✂️  Cropping region: $REGION"
                    # Region format: X,Y,W,H
                    X=$(echo $REGION | cut -d',' -f1)
                    Y=$(echo $REGION | cut -d',' -f2)
                    W=$(echo $REGION | cut -d',' -f3)
                    H=$(echo $REGION | cut -d',' -f4)
                    CROP_GEOMETRY="${W}x${H}+${X}+${Y}"
                fi

                # Apply crop
                convert "$WORK_FILE" -crop "$CROP_GEOMETRY" +repage "$CROP_FILE" 2>/dev/null
                if [ $? -eq 0 ]; then
                    rm "$WORK_FILE"
                    WORK_FILE="$CROP_FILE"
                else
                    echo "⚠️  Warning: crop failed, using original"
                fi
            fi
        fi

        # Step 2: Apply zoom if requested
        if [ -n "$ZOOM_FACTOR" ]; then
            echo "🔍 Zooming ${ZOOM_FACTOR}x..."
            ZOOM_PERCENT=$(echo "$ZOOM_FACTOR * 100" | bc)
            convert "$WORK_FILE" -resize ${ZOOM_PERCENT}% "$SCREENSHOT_PATH" 2>/dev/null

            if [ $? -eq 0 ]; then
                rm "$WORK_FILE" 2>/dev/null
            else
                echo "⚠️  Warning: zoom failed, keeping previous result"
                mv "$WORK_FILE" "$SCREENSHOT_PATH"
            fi
        else
            mv "$WORK_FILE" "$SCREENSHOT_PATH"
        fi
    fi
fi

# Report success
echo "✅ Screenshot saved: $SCREENSHOT_PATH"
echo "File size: $(du -h "$SCREENSHOT_PATH" | cut -f1)"
if [ -n "$ZONE" ]; then
    echo "Zone: $ZONE"
fi
if [ -n "$REGION" ]; then
    echo "Region: $REGION"
fi
if [ -n "$ZOOM_FACTOR" ]; then
    echo "Zoom level: ${ZOOM_FACTOR}x"
fi
echo ""
echo "To view, Claude can read: $SCREENSHOT_PATH"
