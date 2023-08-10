local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.color_scheme = 'iceberg-dark'
local scheme = wezterm.get_builtin_color_schemes()['iceberg-dark']

config.colors = {
    background = 'black',
}

config.window_padding = {
    left = '30',
    right = '30',
    top = '30',
    bottom = '30',
}

config.window_background_opacity = 1.0
config.macos_window_background_blur = 100
config.window_decorations = "RESIZE"
config.font = wezterm.font 'JetBrainsMono Nerd Font Mono'
config.enable_tab_bar = false
config.use_fancy_tab_bar = true
config.font_size = 15.5
config.window_close_confirmation = 'NeverPrompt'

return config
