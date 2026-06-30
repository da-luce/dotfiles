#!/usr/bin/env bash
# Toggle Wi-Fi power, then refresh the item.

if networksetup -getairportpower en0 | grep -q "On$"; then
  networksetup -setairportpower en0 off
else
  networksetup -setairportpower en0 on
fi

sleep 1
NAME="$NAME" "$HOME/.config/sketchybar/plugins/wifi.sh"
