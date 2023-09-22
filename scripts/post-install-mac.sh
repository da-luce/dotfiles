# Install programs using Homebrew

# Make sure we're all set and update
brew doctor
brew tap homebrew/cask-versions

# Dev
brew install starship
brew install autojump
brew install ncurses
brew install meson
brew install gdb
brew install lua
brew install tree-sitter
brew install luajit
brew install neovim

# Neovim package manager
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

brew install --cask multipass
brew install --cask wezterm
brew install --cask visual-studio-code
brew install --cask xquartz

# Social media
brew install --cask slack
brew install --cask discord

# General
brew install --cask obsidian
brew install --cask spotify
brew install --cask todoist
brew install --cask bitwarden
brew install --cask google-drive
brew install --cask microsoft-office
brew install --cask firefox-developer-edition