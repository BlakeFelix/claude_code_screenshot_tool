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
DASHBOARD_MODE=false

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
        --dashboard)
            DASHBOARD_MODE=true
            shift
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
            echo "  --dashboard          Smart mode for dashboard chat (center @ 2.5x)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Available zones:"
            echo "  top-left, top-right, bottom-left, bottom-right"
            echo "  center, top, middle, bottom, left, right"
            echo ""
            echo "Recursive zones (v1.3.0+):"
            echo "  Use colon to chain zones: --zone bottom:right"
            echo "  Example: bottom:right = right half of bottom third"
            echo "  Example: center:bottom-right = bottom-right quadrant of center"
            echo ""
            echo "Examples:"
            echo "  $0                              # Full screen capture"
            echo "  $0 --dashboard                  # Smart dashboard mode (legible text)"
            echo "  $0 --window Firefox             # Capture Firefox window"
            echo "  $0 --zone bottom --zoom 2       # Bottom third, zoomed 2x"
            echo "  $0 --zone bottom:right --zoom 3 # Right of bottom, 3x zoom"
            echo "  $0 --zone center:center --zoom 4 # Center of center (progressive zoom)"
            echo "  $0 --region 100,100,800,600     # Custom 800x600 region"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Apply dashboard mode preset
if [ "$DASHBOARD_MODE" = true ]; then
    echo "🎯 Dashboard mode: capturing center chat area with enhanced legibility"
    ZONE="center"
    ZOOM_FACTOR="2.5"
fi

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

# Function to calculate crop geometry for a single zone
calculate_zone_geometry() {
    local ZONE_NAME=$1
    local CUR_WIDTH=$2
    local CUR_HEIGHT=$3

    case "$ZONE_NAME" in
        top-left)
            local W=$((CUR_WIDTH / 2))
            local H=$((CUR_HEIGHT / 2))
            echo "${W}x${H}+0+0"
            ;;
        top-right)
            local W=$((CUR_WIDTH / 2))
            local H=$((CUR_HEIGHT / 2))
            local X=$((CUR_WIDTH / 2))
            echo "${W}x${H}+${X}+0"
            ;;
        bottom-left)
            local W=$((CUR_WIDTH / 2))
            local H=$((CUR_HEIGHT / 2))
            local Y=$((CUR_HEIGHT / 2))
            echo "${W}x${H}+0+${Y}"
            ;;
        bottom-right)
            local W=$((CUR_WIDTH / 2))
            local H=$((CUR_HEIGHT / 2))
            local X=$((CUR_WIDTH / 2))
            local Y=$((CUR_HEIGHT / 2))
            echo "${W}x${H}+${X}+${Y}"
            ;;
        center)
            local W=$((CUR_WIDTH / 2))
            local H=$((CUR_HEIGHT / 2))
            local X=$((CUR_WIDTH / 4))
            local Y=$((CUR_HEIGHT / 4))
            echo "${W}x${H}+${X}+${Y}"
            ;;
        top)
            local H=$((CUR_HEIGHT / 3))
            echo "${CUR_WIDTH}x${H}+0+0"
            ;;
        middle)
            local H=$((CUR_HEIGHT / 3))
            local Y=$((CUR_HEIGHT / 3))
            echo "${CUR_WIDTH}x${H}+0+${Y}"
            ;;
        bottom)
            local H=$((CUR_HEIGHT / 3))
            local Y=$((CUR_HEIGHT * 2 / 3))
            echo "${CUR_WIDTH}x${H}+0+${Y}"
            ;;
        left)
            local W=$((CUR_WIDTH / 2))
            echo "${W}x${CUR_HEIGHT}+0+0"
            ;;
        right)
            local W=$((CUR_WIDTH / 2))
            local X=$((CUR_WIDTH / 2))
            echo "${W}x${CUR_HEIGHT}+${X}+0"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
    return 0
}

# Post-processing (crop zones/regions, then zoom)
if [ "$NEEDS_PROCESSING" = true ]; then
    if ! command -v convert &> /dev/null; then
        echo "⚠️  Warning: imagemagick not found, skipping post-processing"
        echo "  Install with: sudo apt-get install imagemagick"
        mv "$CAPTURE_PATH" "$SCREENSHOT_PATH"
    else
        WORK_FILE="$CAPTURE_PATH"

        # Step 1: Apply zones or region
        if [ -n "$ZONE" ] || [ -n "$REGION" ]; then
            if [ -n "$ZONE" ]; then
                # Parse recursive zones (split by colon)
                IFS=':' read -ra ZONE_ARRAY <<< "$ZONE"
                echo "✂️  Cropping zone chain: $ZONE (${#ZONE_ARRAY[@]} levels)"

                # Apply each zone sequentially
                for i in "${!ZONE_ARRAY[@]}"; do
                    ZONE_NAME="${ZONE_ARRAY[$i]}"
                    ZONE_NUM=$((i + 1))

                    # Get current dimensions
                    DIMENSIONS=$(identify -format "%wx%h" "$WORK_FILE" 2>/dev/null)
                    WIDTH=$(echo $DIMENSIONS | cut -d'x' -f1)
                    HEIGHT=$(echo $DIMENSIONS | cut -d'x' -f2)

                    if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
                        echo "⚠️  Warning: Could not determine image dimensions at level $ZONE_NUM"
                        break
                    fi

                    # Calculate geometry for this zone
                    CROP_GEOMETRY=$(calculate_zone_geometry "$ZONE_NAME" "$WIDTH" "$HEIGHT")

                    if [ $? -ne 0 ] || [ -z "$CROP_GEOMETRY" ]; then
                        echo "❌ Unknown zone at level $ZONE_NUM: '$ZONE_NAME'"
                        echo "Available: top-left, top-right, bottom-left, bottom-right, center, top, middle, bottom, left, right"
                        rm "$WORK_FILE" 2>/dev/null
                        exit 1
                    fi

                    echo "  ↳ Level $ZONE_NUM: $ZONE_NAME (${WIDTH}x${HEIGHT} → ${CROP_GEOMETRY})"

                    # Apply this zone's crop
                    TEMP_CROP="${SCREENSHOT_DIR}/zone_${ZONE_NUM}_${TIMESTAMP}.png"
                    convert "$WORK_FILE" -crop "$CROP_GEOMETRY" +repage "$TEMP_CROP" 2>/dev/null

                    if [ $? -eq 0 ] && [ -f "$TEMP_CROP" ]; then
                        rm "$WORK_FILE" 2>/dev/null
                        WORK_FILE="$TEMP_CROP"
                    else
                        echo "⚠️  Warning: crop failed at level $ZONE_NUM"
                        break
                    fi
                done

            elif [ -n "$REGION" ]; then
                echo "✂️  Cropping region: $REGION"
                # Region format: X,Y,W,H
                X=$(echo $REGION | cut -d',' -f1)
                Y=$(echo $REGION | cut -d',' -f2)
                W=$(echo $REGION | cut -d',' -f3)
                H=$(echo $REGION | cut -d',' -f4)
                CROP_GEOMETRY="${W}x${H}+${X}+${Y}"

                TEMP_CROP="${SCREENSHOT_DIR}/region_${TIMESTAMP}.png"
                convert "$WORK_FILE" -crop "$CROP_GEOMETRY" +repage "$TEMP_CROP" 2>/dev/null

                if [ $? -eq 0 ] && [ -f "$TEMP_CROP" ]; then
                    rm "$WORK_FILE" 2>/dev/null
                    WORK_FILE="$TEMP_CROP"
                else
                    echo "⚠️  Warning: region crop failed"
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
