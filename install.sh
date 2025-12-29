#!/bin/bash
# Installation script for multi_qwerty, multi_cyrillic, multi_compose layouts
# Installs XKB symbol files and sets up system configuration

set -e

SYMBOLS_DIR="./symbols"
XKB_SYMBOLS_PATH="/usr/share/X11/xkb/symbols"

echo "=== Multi-Layout Installation Script ==="
echo ""

# --- Custom layout registration snippets ---
EVDEV_XML_SNIPPET='<layout>\n  <configItem>\n    <name>multi_qwerty</name>\n    <shortDescription>qwe</shortDescription>\n    <description>QWERTY (custom, with compose)</description>\n    <languageList>\n      <iso639Id>us</iso639Id>\n    </languageList>\n  </configItem>\n</layout>\n<layout>\n  <configItem>\n    <name>multi_cyrillic</name>\n    <shortDescription>cyr</shortDescription>\n    <description>Cyrillic (custom, with compose)</description>\n    <languageList>\n      <iso639Id>ru</iso639Id>\n    </languageList>\n  </configItem>\n</layout>'
EVDEV_LST_SNIPPET='multi_qwerty        Multi QWERTY (custom, with compose)\nmulti_cyrillic      Multi Cyrillic (custom, with compose)'

# --- Helper: Patch XML/LST if not present ---
patch_if_missing() {
    local file="$1"
    local pattern="$2"
    local snippet="$3"
    if ! grep -q "$pattern" "$file"; then
        echo "Patching $file (backup: $file.bak) ..."
        sudo cp "$file" "$file.bak"
        if [[ "$file" == *.xml ]]; then
            # Insert before </layoutList>
            sudo sed -i "/<\/layoutList>/i $snippet" "$file"
        elif [[ "$file" == *.lst ]]; then
            # Insert before the first empty line after the layout section
            # Find the line number where the layout section ends (first empty line after a layout entry)
            local insert_line=$(awk '/^! layout/{flag=1; next} /^$/{if(flag){print NR; exit}}' "$file")
            if [ -n "$insert_line" ]; then
                sudo awk -v n="$insert_line" -v s="$snippet" 'NR==n{print s} 1' "$file" | sudo tee "$file.tmp" > /dev/null
                sudo mv "$file.tmp" "$file"
            else
                # Fallback: append to end
                echo -e "$snippet" | sudo tee -a "$file" > /dev/null
            fi
        else
            # Append to end
            echo -e "$snippet" | sudo tee -a "$file" > /dev/null
        fi
    else
        echo "$file already contains custom layouts."
    fi
}

# Check if symbols directory exists
if [ ! -d "$SYMBOLS_DIR" ]; then
    echo "✗ Error: symbols directory not found in current directory"
    exit 1
fi

# Check if required files exist
for file in multi_qwerty multi_cyrillic; do
    if [ ! -f "$SYMBOLS_DIR/$file" ]; then
        echo "✗ Error: $file not found"
        exit 1
    fi
done

echo "Step 1: Installing symbol files to $XKB_SYMBOLS_PATH..."
sudo cp "$SYMBOLS_DIR/multi_qwerty" "$XKB_SYMBOLS_PATH/" || { echo "✗ Failed to install multi_qwerty"; exit 1; }
sudo cp "$SYMBOLS_DIR/multi_cyrillic" "$XKB_SYMBOLS_PATH/" || { echo "✗ Failed to install multi_cyrillic"; exit 1; }
echo "✓ Symbol files installed"
echo ""

echo "Step 1b: Registering layouts in XKB rules..."
for rules in /usr/share/X11/xkb/rules/evdev.xml /usr/share/X11/xkb/rules/evdev.lst /usr/share/X11/xkb/rules/base.xml; do
    if [ -f "$rules" ]; then
        if [[ "$rules" == *.xml ]]; then
            patch_if_missing "$rules" "multi_qwerty" "$EVDEV_XML_SNIPPET"
            patch_if_missing "$rules" "multi_cyrillic" "$EVDEV_XML_SNIPPET"
        else
            patch_if_missing "$rules" "multi_qwerty" "$EVDEV_LST_SNIPPET"
            patch_if_missing "$rules" "multi_cyrillic" "$EVDEV_LST_SNIPPET"
        fi
    fi
done
echo "✓ Layouts registered in XKB rules"
echo ""

# --- Patch /etc/default/keyboard ---
echo "Step 1c: Setting system default keyboard layout..."
if [ -f /etc/default/keyboard ]; then
    sudo cp /etc/default/keyboard /etc/default/keyboard.bak
    sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,ru"/' /etc/default/keyboard
    sudo sed -i 's/^XKBMODEL=.*/XKBMODEL="pc105"/' /etc/default/keyboard
    sudo sed -i 's/^XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard
    sudo sed -i 's/^XKBOPTIONS=.*/XKBOPTIONS="grp:caps_toggle"/' /etc/default/keyboard
    echo "✓ /etc/default/keyboard updated (backup: /etc/default/keyboard.bak)"
else
    echo "✗ /etc/default/keyboard not found, skipping."
fi
echo ""

# --- Patch /etc/X11/xorg.conf.d/00-keyboard.conf ---
XORG_CONF="/etc/X11/xorg.conf.d/00-keyboard.conf"
if [ -f "$XORG_CONF" ]; then
    sudo cp "$XORG_CONF" "$XORG_CONF.bak"
    sudo sed -i 's/Option\s\+"XkbLayout".*/Option "XkbLayout" "us,ru"/' "$XORG_CONF"
    sudo sed -i 's/Option\s\+"XkbModel".*/Option "XkbModel" "pc105"/' "$XORG_CONF"
    sudo sed -i 's/Option\s\+"XkbVariant".*/Option "XkbVariant" ""/' "$XORG_CONF"
    sudo sed -i 's/Option\s\+"XkbOptions".*/Option "XkbOptions" "grp:caps_toggle"/' "$XORG_CONF"
    echo "✓ $XORG_CONF updated (backup: $XORG_CONF.bak)"
else
    echo "✗ $XORG_CONF not found, skipping."
fi
echo ""

echo "Step 2: Testing keyboard layout compilation..."
cat > /tmp/test_multi.xkb << 'EOF'
xkb_keymap {
    xkb_keycodes { include "evdev+aliases(qwerty)" };
    xkb_types { include "complete" };
    xkb_compat { include "complete" };
    xkb_symbols {
        include "pc(pc105)+inet(evdev)"
        include "multi_qwerty"
        include "multi_cyrillic:2"
    };
    xkb_geometry { include "pc(pc105)" };
};
EOF
xkbcomp -I/usr/share/X11/xkb /tmp/test_multi.xkb /tmp/test_multi.out > /dev/null 2>&1 || { echo "✗ Keyboard layout compilation failed"; exit 1; }
echo "✓ Keyboard layout compiles successfully"
echo ""

echo "Step 3: Loading keyboard layout..."
setxkbmap -layout multi_qwerty,multi_cyrillic -option grp:caps_select || { echo "✗ Failed to load layout"; exit 1; }
echo "✓ Layout loaded successfully"
echo ""

echo "Current keyboard layout:"
setxkbmap -query
echo ""

echo "=== Installation Complete ==="
echo ""
echo "Usage:"
echo "  - Press Caps Lock to lock qwerty"
echo "  - Press Shift + Caps Lock to lock cyrillic"
echo "  - Press Right Alt for Level 3 (compose layer)"
echo "  - Press Right Alt + Shift for Level 4 (compose shift layer)"
echo ""
echo "To make this permanent on X11, add to ~/.xinitrc or ~/.xsession:"
echo "  setxkbmap -layout multi_qwerty,multi_cyrillic -option grp:caps_select"
echo ""
echo "For GNOME/KDE, the layout can be added via Settings > Region & Language"
