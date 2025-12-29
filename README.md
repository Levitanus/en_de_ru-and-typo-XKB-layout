# Multi-Layout Keyboard System (multi_qwerty + multi_cyrillic + multi_compose)

## Overview

This is a modular XKB keyboard layout system that provides:
- **Layout 1**: English QWERTY with extended symbols (multi_qwerty)
- **Layout 2**: Russian Cyrillic with extended symbols (multi_cyrillic)
- **Compose Layer**: Shared alternate characters and special symbols (multi_compose) accessible via Right Alt

## Features

- **Dual Layout Support**: Switch between QWERTY and Cyrillic using Caps Lock
- **Compose/Level 3 Access**: Right Alt activates Level 3 (alternate symbols)
- **Level 4 Access**: Right Alt + Shift activates Level 4
- **Wayland Compatible**: Works on both X11 and Wayland
- **Modular Design**: Each layout is a separate, independent file

## Files

- `symbols/multi_qwerty` - Base QWERTY layout with compose layer reference
- `symbols/multi_cyrillic` - Base Cyrillic layout with compose layer reference
- `install.sh` - Automated installation script
- `00-keyboard.conf` - X11 persistent configuration file

## Installation

### Quick Install (Recommended)

```bash
cd /path/to/en_de_ru-and-typo-XKB-layout
./install.sh
```

This will:
1. Copy symbol files to `/usr/share/X11/xkb/symbols/`
2. Validate files with xkbcomp
3. Load the layout immediately

### Manual Install

```bash
# Copy files to system
sudo cp symbols/multi_{qwerty,cyrillic,compose} /usr/share/X11/xkb/symbols/

# Load layout (temporary, until reboot)
setxkbmap -layout multi_qwerty,multi_cyrillic -option grp:caps_toggle
```

### Persistent Configuration

#### For X11/Xorg:

Option 1: Add to `~/.xinitrc` or `~/.xsession`:
```bash
setxkbmap -layout multi_qwerty,multi_cyrillic -option grp:caps_select
```

Option 2: System-wide via xorg.conf (requires root):
```bash
sudo cp 00-keyboard.conf /etc/X11/xorg.conf.d/
```

#### For Wayland (GNOME/KDE):

Use the desktop environment's Settings:
- GNOME: Settings → Region & Language → Input Sources → Add "English (multi_qwerty)" and "Russian (multi_cyrillic)"
- KDE: System Settings → Input Devices → Keyboard → Layouts → Add layouts

Then set Caps Lock as the group toggle via Layout Options.

## Usage

### Keyboard Shortcuts

| Action | Key |
|--------|-----|
| Switch to qwerty | Caps Lock |
| Switch to cyrillic | Shift + Caps Lock |
| Level 3 (Compose) | Right Alt |
| Level 4 (Compose Shift) | Right Alt + Shift |

### Compose Layer Examples

When you press Right Alt, you gain access to:
- **Letters**: ä, ü, ö, ñ, etc.
- **Superscripts**: ¹, ², ³, ⁴, ⁵, ⁶, ⁷, ⁸, ⁹, ⁰
- **Subscripts**: ₁, ₂, ₃, ₄, ₅, ₆, ₇, ₈, ₉, ₀
- **Cyrillic Alternates**: ЩЪ, ЫЁ (held on Level 3/4 in Cyrillic mode)
- **Special Symbols**: Various punctuation and math symbols

## Troubleshooting

### Layout won't load with setxkbmap

**Symptom**: "Error loading new keyboard description"

**Solutions**:
1. Verify files are in `/usr/share/X11/xkb/symbols/`:
   ```bash
   ls -la /usr/share/X11/xkb/symbols/multi_*
   ```
2. Check compilation:
   ```bash
   xkbcomp -I/usr/share/X11/xkb /usr/share/X11/xkb/symbols/multi_qwerty /tmp/test.xkb
   ```
3. Reinstall: Run `./install.sh` again

### Compose layer (Right Alt) not working

1. Verify layout is loaded:
   ```bash
   setxkbmap -query
   ```
   Should show: `layout: multi_qwerty,multi_cyrillic`

2. Check that `multi_compose` file exists and is included in multi_qwerty/multi_cyrillic:
   ```bash
   grep "include.*multi_compose" /usr/share/X11/xkb/symbols/multi_*
   ```

3. Test specific key:
   ```bash
   xmodmap -pk | grep -i "shift+alt"
   ```

### On Wayland: Layout not persisting after reboot

Wayland uses desktop environment settings. Configure layouts via:
- GNOME: Settings → Region & Language
- KDE: System Settings → Input Devices → Keyboard

## Development

To modify layouts:

1. Edit files in `symbols/` directory
2. Test with xkbcomp:
   ```bash
   xkbcomp -I/usr/share/X11/xkb /usr/share/X11/xkb/symbols/multi_qwerty /tmp/test.xkb
   ```
3. Reload to system:
   ```bash
   sudo cp symbols/multi_* /usr/share/X11/xkb/symbols/
   ```
4. Test with setxkbmap:
   ```bash
   setxkbmap -layout multi_qwerty,multi_cyrillic -option grp:caps_toggle
   ```

## Key Type Reference

The layouts use these XKB key types:
- **ALPHABETIC**: Shift produces uppercase (letters)
- **TWO_LEVEL**: Shift produces alternate symbol (numbers, punctuation)
- **FOUR_LEVEL**: Four levels via Shift + Level3 modifier
- **FOUR_LEVEL_ALPHABETIC**: Four alphabetic levels
- **FOUR_LEVEL_SEMIALPHABETIC**: Mixed letter/symbol four-level keys
- **PC_ALT_LEVEL2**: Alt key for Level 2
- **PC_CONTROL_LEVEL2**: Control key for Level 2

## Technical Notes

- **Group Switching**: Uses `grp:caps_toggle` option to switch layouts via Caps Lock
- **Compose Access**: Right Alt (RALT) mapped to ISO_Level3_Shift for Level 3/4
- **Include Mechanism**: multi_qwerty and multi_cyrillic both `include "multi_compose"` for Level 5 symbols
- **Compatibility**: Works with both X11 (Xorg) and Wayland (via XKB compatibility layer)

## License

Same as original en_de_ru_typo layout. See LICENSE.md
