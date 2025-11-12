# Screenshot Tool for Claude Code

**Enable Claude to see your browser/dashboard state directly** - No more manual screenshots!

## What is This?

A simple bash script that lets Claude Code take screenshots and view them automatically during debugging sessions. Perfect for debugging web dashboards, UI issues, or any visual state.

## Why?

When debugging dashboards or UIs with Claude Code, you often need to show Claude what's on screen. This tool:
- ✅ Takes screenshots with a single command
- ✅ Claude can read them directly (multimodal support)
- ✅ Saves with timestamps for tracking
- ✅ Zero user intervention after setup

**Before**: Manual screenshots, copying paths, slow feedback loop
**After**: `~/screenshot_dashboard.sh` and Claude sees it instantly

## Installation

### Prerequisites

- Linux with X11 (tested on Ubuntu)
- `scrot` screenshot utility
- `xdotool` for window-specific screenshots (optional)
- `imagemagick` for cleaner window captures (optional)
- Claude Code with multimodal image support

```bash
# Install required tools
sudo apt-get install scrot xdotool imagemagick

# Download and install
git clone https://github.com/YOUR_USERNAME/screenshot-tool-claude
cd screenshot-tool-claude
chmod +x screenshot_dashboard.sh
cp screenshot_dashboard.sh ~/Desktop/
```

## Usage

### Basic Screenshot (Full Screen)

```bash
~/Desktop/screenshot_dashboard.sh
```

**Output**:
```
✅ Screenshot saved: /home/user/Pictures/Screenshots/dashboard_20251111_153045.png
File size: 2.3M

To view, Claude can read: /home/user/Pictures/Screenshots/dashboard_20251111_153045.png
```

### Capture Specific Window

Capture just one window instead of the full screen - useful when windows are overlapping or you want to focus on specific content:

```bash
# Capture by window title (partial match works)
~/Desktop/screenshot_dashboard.sh --window "Firefox"
~/Desktop/screenshot_dashboard.sh --window "Kimi"
~/Desktop/screenshot_dashboard.sh -w "Claude"
```

**Output**:
```
📸 Capturing window: Kimi K2 Thinking - Deep Reasoning (ID: 12345678)
✅ Screenshot saved: /home/user/Pictures/Screenshots/dashboard_20251111_153045.png
File size: 892K
```

**Benefits of window capture:**
- No obscured content from overlapping windows
- Smaller file sizes (only one window)
- Focus on specific application
- Claude can run autonomously (no manual clicking)

### With Claude Code

Just run the script and Claude will see the output path:

```
User: "screenshot the dashboard"
Claude: *runs screenshot_dashboard.sh*
Claude: *reads the screenshot image*
Claude: "I can see the error in the console..."
```

Or for specific windows:

```
User: "screenshot the Kimi dashboard"
Claude: *runs screenshot_dashboard.sh --window "Kimi"*
Claude: *reads the screenshot of just that window*
Claude: "I can see the Thinking dashboard has an error message..."
```

## How It Works

1. **Full screen mode**: Uses `scrot` to capture entire screen
2. **Window mode**: Uses `xdotool` to find window by name, then `imagemagick` or `scrot` to capture it
3. Saves to `~/Pictures/Screenshots/` with timestamp
4. Returns path for Claude to read
5. Claude uses multimodal Read tool to view image

## Real-World Example

**Dashboard Debugging Session (Nov 5, 2025)**:
```
User: "the dashboard had some error btw"
Claude: *takes screenshot*
Claude: "I can see AbortSignal.timeout() error in console. This isn't
        supported in all browsers. Let me fix it..."
```

Saved 5+ minutes of back-and-forth describing the error!

## Configuration

### Change Screenshot Directory

Edit line 7 in the script:
```bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
```

## Troubleshooting

**"scrot: command not found"**
```bash
sudo apt-get install scrot
```

**Screenshots are blank/black**
- May be a compositor issue with some window managers
- Try: `scrot -d 1` (1 second delay)

**Claude can't read the screenshot**
- Ensure you're using Claude Code with multimodal support
- Check file path is correct
- Verify image file exists and isn't corrupted

## Advanced Usage

### Add to Claude's Pre-approved Commands

In your Claude Code settings, pre-approve the screenshot command:
```
Bash(~/Desktop/screenshot_dashboard.sh:*)
```

This allows Claude to take screenshots without asking permission each time.

### Multiple Displays

```bash
# Capture specific display
scrot -a 0,0,1920,1080 "$SCREENSHOT_PATH"
```

### Integration with Dashboards

Add a keyboard shortcut or button in your dashboard:
```javascript
// In your web dashboard
function debugWithClaude() {
    fetch('/screenshot').then(() => {
        console.log('Screenshot taken for Claude');
    });
}
```

## Contributing

Pull requests welcome! Potential improvements:
- [ ] Wayland support (alternative to scrot)
- [ ] macOS version (using `screencapture`)
- [ ] Windows version (using PowerShell)
- [x] Capture specific window by title (✅ implemented!)
- [ ] Annotate screenshots before sending to Claude
- [ ] Region selection mode (capture part of screen)
- [ ] Video recording support

## License

MIT License - See LICENSE file

## Credits

Created by Blake & Claude Code during a dashboard debugging session (Nov 5, 2025)

**Inspiration**: "can we workshop a tool for you so I don't have to always do this manually?"

## See Also

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [scrot documentation](https://github.com/resurrecting-open-source-projects/scrot)
