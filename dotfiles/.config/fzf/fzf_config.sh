# Scheme name: Gruvbox dark, hard
# Scheme system: base16
# Scheme author: Dawid Kurek (dawikur@gmail.com), morhetz (https://github.com/morhetz/gruvbox)
# Template author: Tinted Theming (https://github.com/tinted-theming)

# Define color theme
colors="--color=bg+:#3c3836"
colors="$colors --color=bg:#1d2021"
colors="$colors --color=spinner:#8ec07c"
colors="$colors --color=hl:#83a598"
colors="$colors --color=fg:#bdae93"
colors="$colors --color=header:#83a598"
colors="$colors --color=info:#fabd2f"
colors="$colors --color=pointer:#8ec07c"
colors="$colors --color=marker:#8ec07c"
colors="$colors --color=fg+:#ebdbb2"
colors="$colors --color=prompt:#fabd2f"
colors="$colors --color=hl+:#83a598"

# Define layout options
layout="--height 80%"
# Display results from top to bottom (default is bottom to top)
layout="$layout --layout reverse"
# Add a border around the fzf window for better visibility
layout="$layout --border"
# Enable circular scrolling (when you reach bottom, wrap to top and vice versa)
layout="$layout --cycle"
# Allow multiple selections using TAB or Shift-TAB
layout="$layout --multi"
# Show information like matches count inline instead of at bottom
layout="$layout --info=inline"
# Display a header message with basic help information
layout="$layout --header 'CTRL-/ to toggle preview, ? for help'"
# Change the prompt symbol (❯ is a special unicode character)
layout="$layout --prompt ' '"

layout="$layout --style full"

# Define preview options
preview="--preview 'bat --style=numbers --color=always {}'"
# Configure the preview window position and size
preview="$preview --preview-window right:60%:wrap"



# Combine all options
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $colors $layout $preview"