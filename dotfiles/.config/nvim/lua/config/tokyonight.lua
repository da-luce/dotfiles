require("tokyonight").setup({
  style = "night",
  transparent = false,

  on_colors = function(colors)
    colors.bg = "#000000"
    colors.bg_dark = "#000000"
    colors.bg_float = "#000000"
    colors.bg_sidebar = "#000000"
    colors.bg_statusline = "#000000"
  end
  
})
