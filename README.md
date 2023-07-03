# Dotfiles

## Usage

### Cloning this repo

Clone this repository into `.dotfiles/` your home directory. Note that complex configuration files are siloed off into their own submodules. 

### Installing packages

1. Run `post-install-<distro>.sh` to install core packages & libraries
2. Run `make-simlinks.sh` to setup configuration simlinks

### Other scripts

- `copy-ssh-wsl.sh`: copies ssh keys from Windows to `~/.ssh/` when using WSL. Optional argument for Window's username if different from Linux.

