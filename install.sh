#!/bin/bash
set -e

# =============================================================================
# Ubuntu Machine Setup Script
#
# Run:
#   bash <(curl -Ls https://raw.githubusercontent.com/phazonoverload/dotfiles/main/install.sh)
#
# Stdin is redirected from /dev/tty for interactive prompts so this works
# even when piped from curl.
# =============================================================================

DOTFILES_REPO="https://github.com/phazonoverload/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Ensure interactive prompts work even when script is piped from curl
exec < /dev/tty

echo "Starting Ubuntu machine setup..."

# =============================================================================
# System Update & Essential Packages
# =============================================================================

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  build-essential \
  curl \
  wget \
  unzip \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg

# =============================================================================
# Git (install early so we can clone the dotfiles repo)
# =============================================================================

sudo apt install -y git

# =============================================================================
# Clone Dotfiles Repo
# =============================================================================

if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "Dotfiles repo already exists at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull
else
  echo "Cloning dotfiles repo..."
  rm -rf "$DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# =============================================================================
# Configure Git
# =============================================================================

existing_name=$(git config --global user.name 2>/dev/null || true)
existing_email=$(git config --global user.email 2>/dev/null || true)

if [ -n "$existing_name" ]; then
  echo -n "Git username [$existing_name]: "
  read -r username
  username="${username:-$existing_name}"
else
  echo -n 'Git username: '
  read -r username
fi
git config --global user.name "$username"

if [ -n "$existing_email" ]; then
  echo -n "Git email [$existing_email]: "
  read -r mail
  mail="${mail:-$existing_email}"
else
  echo -n 'Git email: '
  read -r mail
fi
git config --global user.email "$mail"

git config --global alias.ac '!git add -A && git commit -m'
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true

# Update the repo .gitconfig with the provided values
sed -i "s/name = .*/name = $username/" "$DOTFILES_DIR/.gitconfig"
sed -i "s/email = .*/email = $mail/" "$DOTFILES_DIR/.gitconfig"

# Generate SSH key (ed25519) if one doesn't already exist
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -C "$mail"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519

  echo ""
  echo "=== Public SSH Key (add to https://github.com/settings/keys) ==="
  cat ~/.ssh/id_ed25519.pub
  echo "================================================================="
  read -rp "Add public key to GitHub and hit [Enter]."
else
  echo "SSH key already exists, skipping generation..."
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
fi

# =============================================================================
# GitHub CLI (gh)
# =============================================================================

if ! command -v gh &> /dev/null; then
  (type -p wget >/dev/null || sudo apt install -y wget) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) \
    && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install -y gh
fi

if ! gh auth status &> /dev/null; then
  gh auth login
else
  echo "gh already authenticated, skipping..."
fi

# =============================================================================
# Python
# =============================================================================

sudo apt install -y python3 python3-pip python3-venv python3-full

if ! command -v python &> /dev/null; then
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
fi

# =============================================================================
# Node.js via Volta
# =============================================================================

export VOLTA_HOME="$HOME/.volta"

if [ ! -d "$VOLTA_HOME" ]; then
  # Download installer, then run (avoids stdin pipe conflicts)
  tmpfile=$(mktemp)
  curl -fsSL https://get.volta.sh -o "$tmpfile"
  bash "$tmpfile" --skip-setup
  rm -f "$tmpfile"
fi

export PATH="$VOLTA_HOME/bin:$PATH"

volta install node@latest
volta install node@lts

# =============================================================================
# GitHub Copilot CLI
# =============================================================================

npm install -g @github/copilot
echo ""
echo "Run 'github-copilot-cli auth' to authenticate Copilot CLI."

# =============================================================================
# Zsh + Oh My Zsh
# =============================================================================

sudo apt install -y zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins (clone or pull if already present)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull
else
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Set zsh as default shell (use sudo to avoid password prompt)
sudo chsh -s "$(which zsh)" "$USER"

# =============================================================================
# Starship Prompt
# =============================================================================

if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# =============================================================================
# Link Dotfiles
# =============================================================================

echo "Linking dotfiles from $DOTFILES_DIR..."
bash "$DOTFILES_DIR/link.sh"

echo ""
echo "=== Setup Complete ==="
echo "Log out and back in (or run 'zsh') for shell changes to take effect."

touch ~/.hushlogin
