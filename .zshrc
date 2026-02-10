# =============================================================================
# Oh My Zsh Configuration
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Disabled in favor of Starship prompt
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  volta
  gh
  docker
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# Environment
# =============================================================================

export EDITOR="fresh"
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Volta (Node version manager)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Local bin (pip install --user, etc.)
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Aliases (loaded from separate file for portability)
# =============================================================================

if [ -f "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

# =============================================================================
# SSH Agent (auto-start if not running)
# =============================================================================

if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null 2>&1
  ssh-add ~/.ssh/id_ed25519 2> /dev/null
fi

# =============================================================================
# Starship Prompt (must be last)
# =============================================================================

eval "$(starship init zsh)"
