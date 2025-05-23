# Dotfiles

## Usage

### Mac

1. Clone the repo: `git clone https://github.com/da-luce/dotfiles ~/.dotfiles`
2. Install [Homebrew](https://brew.sh/)
3. Install [GNU Stow](https://www.gnu.org/software/stow/): `brew install stow`
4. Navigate to the repo directory: `cd ~/.dotfiles`
5. Stow the dotfiles: `stow dotfiles`
6. Install dependencies: `brew bundle --file=install/Brewfile`
