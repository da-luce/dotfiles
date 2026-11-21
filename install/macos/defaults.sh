#!/usr/bin/env bash

set -euo pipefail

[ "$(uname -s)" = "Darwin" ] || { echo "error: macOS only" >&2; exit 1; }

echo "==> Keyboard"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 25

echo "==> Dock"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 2
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock tilesize -int 42
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "genie"

echo "==> Hot corners (1 = disabled)"
for corner in tl tr bl br; do
  defaults write com.apple.dock "wvous-${corner}-corner" -int 1
  defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
done

echo "==> Menu bar"
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0
defaults write com.apple.menuextra.clock ShowAMPM -bool true

echo "==> Finder"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"  # column view
defaults write com.apple.finder NewWindowTarget -string "PfAF"       # All My Files

echo "==> Restarting affected apps"
for app in Dock Finder SystemUIServer; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "Done. Key repeat changes need a logout/login."
