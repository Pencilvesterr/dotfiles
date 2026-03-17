#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/../scripts/utils.sh

register_keyboard_shortcuts() {
    # Register CTRL+/ keyboard shortcut to avoid system beep when pressed
    info "Registering keyboard shortcuts..."
    mkdir -p "$HOME/Library/KeyBindings"
    cat >"$HOME/Library/KeyBindings/DefaultKeyBinding.dict" <<EOF
{
 "^\U002F" = "noop";
}
EOF
}

apply_osx_system_defaults() {
    info "Applying OSX system defaults..."

    # Enable three finger drag
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

    # Don't hide icons on desktop
    defaults write com.apple.finder CreateDesktop -bool false

    # Avoid creating .DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Show path in finder title bar
    defaults write com.apple.finder _FXShowPosixPathInTitle Yes

    # Show hidden files inside the finder
    defaults write com.apple.finder "AppleShowAllFiles" -bool true

    # Show Status Bar
    defaults write com.apple.finder "ShowStatusBar" -bool true

    # Do not show warning when changing the file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    defaults write com.apple.screencapture type -string "png"

    # Set weekly software update checks
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 7

    # Spaces span all displays
    defaults write com.apple.spaces "spans-displays" -bool false

    # Do not rearrange spaces automatically
    # defaults write com.apple.dock "mru-spaces" -bool false

    # Set Dock autohide and to the right
    defaults write com.apple.dock orientation right
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock largesize -float 60
    defaults write com.apple.dock magnification -float 1
    defaults write com.apple.dock "minimize-to-application" -bool false
    defaults write com.apple.dock tilesize -float 45

    # Disable click on desktop to show desktop (Sonoma+)
    defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

    # Disable hot corners in bottom right (br)
    defaults write com.apple.dock wvous-br-corner -int 0
    killall Dock

    # Disable full screen on second monitor for aerospace
    # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
    defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer

    # Show battery percentage in menu bar
    defaults write com.apple.controlcenter BatteryShowPercentage -bool true

    # Show sound icon in menu bar
    defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true

    # Use F1-F12 as standard function keys (require Fn for special functions)
    defaults write -g com.apple.keyboard.fnState -bool true

    # Disable Cmd+Space Spotlight shortcut (frees it up for Alfred)
    # Hotkey 64 = Spotlight search (Cmd+Space), 65 = Spotlight window (Cmd+Option+Space)
    SPOTLIGHT_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled bool false" "$SPOTLIGHT_PLIST" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:enabled bool false" "$SPOTLIGHT_PLIST"
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled bool false" "$SPOTLIGHT_PLIST" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:65:enabled bool false" "$SPOTLIGHT_PLIST"
    # Apply hotkey changes without requiring logout
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
}

remap_capslock_to_escape() {
    # TODO: This didn't work when i last tried it
    info "Remapping Caps Lock to Escape..."
    # Persisted natively via macOS modifier key preferences (same storage as System Settings).
    # HID usage values: Caps Lock = 0x700000039 (30064771129), Escape = 0x700000029 (30064771113)
    # The key "-1--1-0" applies to all keyboards. Takes effect after logout/login.
    defaults write -g com.apple.keyboard.modifiermapping.-1--1-0 -array \
        '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771113</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer></dict>'
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    register_keyboard_shortcuts
    apply_osx_system_defaults
    remap_capslock_to_escape
fi
