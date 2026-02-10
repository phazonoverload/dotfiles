#!/bin/bash
set -e

# =============================================================================
# Ubuntu Machine Setup Script
# Adapted for fresh Ubuntu installs
#
# Run:
#   bash <(curl -Ls https://raw.githubusercontent.com/phazonoverload/dotfiles/main/install.sh)
# =============================================================================

DOTFILES_REPO="https://github.com/phazonoverload/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

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

if [ -d "$DOTFILES_DIR" ]; then
  echo "Dotfiles repo already exists at $DOTFILES_DIR, pulling latest..."
  git -C "$DOTFILES_DIR" pull
else
  echo "Cloning dotfiles repo..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# =============================================================================
# Configure Git
# =============================================================================

echo -n 'Git username: '
read username
git config --global user.name "$username"

echo -n 'Git email: '
read mail
git config --global user.email "$mail"

git config --global alias.ac '!git add -A && git commit -m'
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true

# Generate SSH key (ed25519 over rsa)
ssh-keygen -t ed25519 -C "$mail"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo ""
echo "=== Public SSH Key (add to https://github.com/settings/keys) ==="
cat ~/.ssh/id_ed25519.pub
echo "================================================================="
read -p "Add public key to GitHub and hit [Enter]."

# =============================================================================
# GitHub CLI (gh)
# =============================================================================

(type -p wget >/dev/null || sudo apt install -y wget) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) \
  && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install -y gh

gh auth login

# =============================================================================
# Python
# =============================================================================

sudo apt install -y python3 python3-pip python3-venv python3-full

# Symlink python -> python3 if not already present
if ! command -v python &> /dev/null; then
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
fi

# =============================================================================
# Node.js via Volta
# =============================================================================

export VOLTA_HOME="$HOME/.volta"

curl https://get.volta.sh | bash -s -- --skip-setup

# Source volta into current session immediately
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

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set zsh as default shell
chsh -s "$(which zsh)"

# =============================================================================
# Starship Prompt
# =============================================================================

curl -sS https://starship.rs/install.sh | sh -s -- --yes

# =============================================================================
# Link Dotfiles
# =============================================================================

echo "Linking dotfiles from $DOTFILES_DIR..."
bash "$DOTFILES_DIR/link.sh"

echo ""
echo "=== Setup Complete ==="
echo "Log out and back in (or run 'zsh') for shell changes to take effect."
