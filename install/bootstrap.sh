#!/usr/bin/env bash
# Set up a Mac from this repo.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"

# ---------------------------------------------------------------- helpers ----
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[33m !  %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31merror: %s\033[0m\n' "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '    [dry-run] %s\n' "$*"
  else
    info "$*"
    "$@"
  fi
}

# ---------------------------------------------------------------- profile ----
PROFILE="${1:-}"
case "$PROFILE" in
  headless|desktop) ;;
  *) die "usage: $0 headless|desktop" ;;
esac

[ "$(uname -s)" = "Darwin" ] || die "macOS only"

echo "repo:    $REPO"
echo "profile: $PROFILE"
[ "$DRY_RUN" = "1" ] && echo "mode:    DRY RUN"

# ------------------------------------------------------------- 1 preflight ---
step "Xcode command line tools"
# Prerequisite.
xcode-select -p >/dev/null 2>&1 || die "missing. Run: xcode-select --install"
info "ok: $(xcode-select -p)"

step "Homebrew"
if command -v brew >/dev/null 2>&1; then
  info "already installed: $(command -v brew)"
elif [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] install Homebrew from brew.sh"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for the rest of this script (Apple silicon or Intel).
for prefix in /opt/homebrew /usr/local; do
  if [ -x "$prefix/bin/brew" ]; then
    eval "$("$prefix/bin/brew" shellenv)"
    break
  fi
done

# ---------------------------------------------------------------- 2 brew -----
step "Homebrew packages"

# Trust taps
run brew trust --tap jakehilborn/jakehilborn
if [ "$PROFILE" = "desktop" ]; then
  run brew trust --tap felixkratz/formulae
fi

run brew bundle --file="$REPO/install/brew/Brewfile.core"
run brew bundle --file="$REPO/install/brew/Brewfile.dev"
if [ "$PROFILE" = "desktop" ]; then
  run brew bundle --file="$REPO/install/brew/Brewfile.gui"
else
  info "skipping Brewfile.gui (headless)"
fi

step "Tailscale daemon"
run sudo brew services start tailscale

# ---------------------------------------------------------------- 3 stow -----
step "Symlinking dotfiles"
# Pre-create the parents so stow links individual files
run mkdir -p "$HOME/.config" "$HOME/.shell" "$HOME/.local/bin"
if [ -L "$HOME/.config" ]; then
  warn "~/.config is a symlink to $(readlink "$HOME/.config") — stow folded it."
  warn "Fix once with a plain stow, which unfolds it: stow --no-folding -d \"$REPO\" -t \"$HOME\" dotfiles shared"
  warn "(--restow cannot do it: it errors with 'unstow_contents() called with invalid target')"
fi
run stow --no-folding --restow -d "$REPO" -t "$HOME" dotfiles shared

# ---------------------------------------------------------------- 4 tmux -----
step "tmux plugins"
TPM="$HOME/.config/tmux/plugins/tpm"
if [ -d "$TPM" ]; then
  info "tpm already cloned"
else
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi
if [ -x "$TPM/bin/install_plugins" ]; then
  run "$TPM/bin/install_plugins"
else
  [ "$DRY_RUN" = "1" ] || warn "tpm installer missing; run prefix + I inside tmux"
fi

# --------------------------------------------------------------- 5 hooks -----
step "Agent indicator hooks"
run bash "$REPO/install/hooks.sh"

# ------------------------------------------------------------- 6 desktop -----
if [ "$PROFILE" = "desktop" ]; then
  step "macOS defaults"
  run bash "$REPO/install/macos/defaults.sh"

  step "Rectangle config"
  run bash "$REPO/misc/rectangle/install.sh"

  step "Window border daemon"
  run brew services start borders
else
  step "Desktop steps"
  info "skipped (headless): macOS defaults, Rectangle, borders"

  step "Headless machine settings"
  info "needs sudo; skip with SKIP_HEADLESS=1"
  if [ "${SKIP_HEADLESS:-0}" = "1" ]; then
    info "skipped (SKIP_HEADLESS=1)"
  else
    run bash "$REPO/install/macos/headless.sh"
  fi
fi

# ------------------------------------------------------------- 7 wrap up -----
step "Done — manual steps left"
cat <<'CHECKLIST'
    - Copy ~/.dotfiles/.secrets.env from the old machine (gitignored: VPN_*).
    - gh auth login
    - bw login                 (bitwarden-cli)
    - sudo tailscale up        (prints a URL to authenticate; open it anywhere)
CHECKLIST
if [ "$PROFILE" = "desktop" ]; then
  cat <<'CHECKLIST'
    - Sign in: Google Drive, Slack, Spotify, Obsidian, Todoist, Bitwarden.
    - Keyboards: flash keyboard/corne.vil + keyboard/silakka54.vil with Vial.
    - Tabliss: import misc/tabliss/gruvbox.json in the browser extension.
    - Key-repeat changes need a logout/login to take effect.
CHECKLIST
else
  cat <<'CHECKLIST'
    - Enable Remote Login / Screen Sharing / automatic login:
      see install/README.md, "Headless machine".
CHECKLIST
fi
