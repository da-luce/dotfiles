# Dotfiles

## Usage

### Cloning this repo

1. Create a `.dotfiles/` folder in your home directory using `mkdir ~/.dotfiles/`
2. Move to this directory (`cd ~/.dotfiles/`) and clone into this folder: `git clone https://github.com/da-luce/dotfiles .`

> Note that complex configuration files are siloed off into their own folders. 

### Installing packages

1. Run `post-install-<distro>.sh` to install core packages & libraries
2. Run `ensured-installed-<distro>.sh` to make sure all packages installed successfully
3. Run `make-simlinks.sh` to setup simlinks to config file locations. WARNING: these simlinks will overwrite existing files if they exist.

### Other scripts

- `copy-ssh-wsl.sh`: copies ssh keys from Windows to `~/.ssh/` when using WSL. Optional argument for Window's username if different from Linux.
- `shell-load.sh`: script set to run on shell load by default. Fetches from remote to ensure everything stays up to date.