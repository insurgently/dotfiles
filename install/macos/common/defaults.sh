#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function defaults_ui() {
    # Display battery percentage
    # ref. https://github.com/todd-dsm/mac-ops/issues/39#issuecomment-962459353
    defaults write ~/Library/Preferences/ByHost/com.apple.controlcenter.plist BatteryShowPercentage -bool true
}

function defaults_keyboard() {
    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    # Set a shorter Delay until key repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 25
}

function defaults_trackpad() {

    defaults write -g com.apple.trackpad.scaling 2

    # Trackpad: enable tap to click for this user and for the login screen
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

    # Enable 3-fingers drag
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
}

function defaults_controlcenter() {
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true
}

function defaults_dock() {
    # Automatically hide and show the Dock
    defaults write com.apple.dock autohide -bool true
    # Set the icon size of Dock items to 30 pixels
    defaults write com.apple.dock tilesize -int 30
    # Disable rearrangement of Mission Control
    defaults write com.apple.dock mru-spaces -bool false

    # Remove all the icons in the Dock
    defaults write com.apple.dock persistent-apps -array ""
    defaults write com.apple.dock recent-apps -array ""
    defaults write com.apple.dock persistent-others -array ""

    function dock_item() {
        local app_file_path="$1"
        printf '
        <dict>
            <key>tile-data</key>
                <dict>
                    <key>file-data</key>
                        <dict>
                            <key>_CFURLString</key><string>%s</string>
                            <key>_CFURLStringType</key><integer>0</integer>
                        </dict>
                </dict>
        </dict>', "${app_file_path}"
    }

    function get_system_app_path() {
        local system_preferences_path="/System/Applications/System Preferences.app/"
        local system_settings_path="/System/Applications/System Settings.app/"

        if [ -e "${system_preferences_path}" ]; then
            echo "${system_preferences_path}"
        elif [ -e "${system_settings_path}" ]; then
            # for Ventura
            echo "${system_settings_path}"
        else
            echo "Could not found system app ${system_preferences_path} and ${system_settings_path}" >&2
            exit 1
        fi
    }
}

function defaults_finder() {

    # Set Home directory as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    defaults write com.apple.finder FXPreferredGroupBy -string "Name"
    defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Enabling the “Remove items from the Trash after 30 days”
    defaults write com.apple.finder FXRemoveOldTrashItems -bool true
}

function defaults_screencapture() {
    # Save screenshots to ${HOME}/Pictures/
    defaults write com.apple.screencapture location -string "${HOME}/Pictures/"
    defaults write com.apple.screencapture name -string "Screen Shot"

    # disable the floating screenshot thumbnail
    defaults write com.apple.screencapture show-thumbnail -bool false
}

function defaults_assistant() {
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false
    defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool false
}

function defaults_iterm2() {

    #
    # Additional defaults settings can be found in `.chezmoiscripts/macos/run_once_04-install-iterm2.sh.tmpl`
    #

    # Don’t display the annoying prompt when quitting iTerm
    defaults write com.googlecode.iterm2 PromptOnQuit -bool false

    # Set the custom fonder to load preferences
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

    # Disable tip of the day
    defaults write com.googlecode.iterm2 NoSyncTipsDisabled -bool true
}

function kill_affected_applications() {
    local apps=(
        "Activity Monitor"
        "Calendar"
        "cfprefsd"
        "Dock"
        "Finder"
        # "Google Chrome Canary"
        # "Google Chrome"
        "SizeUp"
        "SystemUIServer"
        # "Terminal" # disable because the setup script is running in the Terminal
        "Transmission"
        "Twitter"
    )
    for app in "${apps[@]}"; do
        killall "${app}" || echo "Process \`${app}\` was not running."
    done
}

function main() {

    defaults_ui
    defaults_dock
    defaults_finder
    defaults_iterm2
    defaults_keyboard
    defaults_trackpad
    defaults_assistant
    defaults_controlcenter
    defaults_screencapture

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
