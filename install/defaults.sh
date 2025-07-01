# Hide Dock
defaults write com.apple.dock autohide -bool true && killall Dock
defaults write com.apple.dock autohide-delay -float 2 && killall Dock
defaults write com.apple.dock no-bouncing -bool FALSE && killall Dock