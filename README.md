# Dotfiles

## Setup

```sh
xcode-select --install # needed for git
gh auth login
git clone https://github.com/da-luce/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install/bootstrap.sh desktop     # or: headless
```

`bootstrap.sh` installs everything needed.

Profiles:

- `headless` — CLI only
- `desktop` — adds casks, fonts, macOS plist settings, window management

## Manual steps after a run

- Store the Secrets Manager machine account token so fnox can read secrets:
  `fnox set -g --provider kc BWS_ACCESS_TOKEN`
- Remote Login, Screen Sharing, automatic login on headless machine - 
  see [install/README.md](install/README.md#headless-machine)
- Importing `misc/tabliss/gruvbox.json` into the Tabliss extension

## Notes

Run stow with `--no-folding` so it links individual files

## TODO

- [ ] Add unit tests to determine a config will work!
- [ ] Merge any necessary changes from `amazon` branch over to `main`
