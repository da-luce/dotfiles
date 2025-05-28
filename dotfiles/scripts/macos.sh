defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false # disable press and hold for vscodeo

install_jetbrains_mono() {
  curl -L -o JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
  unzip JetBrainsMono.zip -d ~/Library/Fonts/
  rm JetBrainsMono.zip
  echo "JetBrains Mono font has been installed successfully!"
}

install_jetbrains_mono

echo "Changing shell to bash"
chsh -s /bin/bash
