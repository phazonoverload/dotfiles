#!/bin/bash
set -e

# =============================================================================
# Symlink dotfiles from this repo into $HOME
# Backs up any existing files before overwriting.
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

files=(
  .zshrc
  .aliases
  .curlrc
  .editorconfig
  .gitconfig
  .inputrc
  .npmrc
)

echo "Linking dotfiles from $DOTFILES_DIR to $HOME"

for file in "${files[@]}"; do
  src="$DOTFILES_DIR/$file"
  dest="$HOME/$file"

  if [ ! -f "$src" ]; then
    echo "  SKIP $file (not found in repo)"
    continue
  fi

  # Back up existing file if it exists and is not already a symlink to our repo
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$dest" "$BACKUP_DIR/$file"
    echo "  BACKUP $file -> $BACKUP_DIR/$file"
  fi

  ln -sf "$src" "$dest"
  echo "  LINK $file -> $dest"
done

# Starship config goes to ~/.config/starship.toml
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
  mkdir -p "$HOME/.config"
  dest="$HOME/.config/starship.toml"
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$dest" "$BACKUP_DIR/starship.toml"
    echo "  BACKUP starship.toml -> $BACKUP_DIR/starship.toml"
  fi
  ln -sf "$DOTFILES_DIR/starship.toml" "$dest"
  echo "  LINK starship.toml -> $dest"
fi

echo "Done."
