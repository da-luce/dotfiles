#!/usr/bin/env bash
# Monokai Pro palette (0xAARRGGBB), auto-adapting to macOS appearance.
# AppleInterfaceStyle is set only in dark mode; absent/erroring means light.

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  ### Monokai Pro (Spectrum) — dark ###
  export BAR_COLOR=0xe62d2a2e   # bar background
  export SURFACE=0x33fcfcfa     # pill background
  export WHITE=0xfffcfcfa       # foreground
  export GREY=0xff727072        # dim / separators
  export ACCENT=0xffffd866      # active space, front app
  export MAGENTA=0xffab9df2      # clock
  export CYAN=0xff78dce8         # volume
  export GREEN=0xffa9dc76
  export YELLOW=0xffffd866
  export RED=0xffff6188
else
  ### Monokai Pro (Light Sun) — light ###
  export BAR_COLOR=0xe6faf4ee   # bar background
  export SURFACE=0x1a2c232e     # pill background (subtle dark wash)
  export WHITE=0xff2c232e       # foreground (dark text)
  export GREY=0xff948a8b        # dim / separators
  export ACCENT=0xffb86052      # active space, front app
  export MAGENTA=0xff6e59c7      # clock
  export CYAN=0xff1c8ca8         # volume
  export GREEN=0xff218871
  export YELLOW=0xffa1851f
  export RED=0xffce4770
fi
