# Install Homebrew and add to path
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.bash_profile && source ~/.bash_profile

# Make sure we're all set and update
brew doctor
brew tap homebrew/cask-versions

# Dev
brew install starship
brew install autojump
brew install --cask multipass
brew install --cask wezterm
brew install --cask visual-studio-code

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

# Update path
echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.bash_profile && source ~/.bash_profile
echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.bash_profile && source ~/.bash_profile