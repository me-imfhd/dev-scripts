# ============================================================================
# ~/.zshrc
#
#   1. Basics & cross-platform shell behavior
#   2. Shared paths & cross-platform tooling (macOS + Linux)
#   3. Platform-specific setup
#
# Ordering matters in a few places:
#   - Powerlevel10k instant prompt must stay near the top.
#   - Homebrew's fpath setup must happen before compinit.
#   - Bun's completion script must load after compinit.
# ============================================================================


# ============================================================================
# 1. BASICS & CROSS-PLATFORM SHELL BEHAVIOR
# ============================================================================

# --- Powerlevel10k instant prompt (must stay near the top) ------------------
# Initialization code that may require console input (passwords, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- History ----------------------------------------------------------------
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- Keybindings ------------------------------------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# --- Completion styling -----------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- Aliases ----------------------------------------------------------------
alias ls='ls --color'
alias vim='nvim'
alias vi='nvim'
alias c='clear'

# --- Zinit, plugins, and prompt (cross-platform) ----------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if it isn't there yet.
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Prompt customization: run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ============================================================================
# 2. SHARED PATHS & CROSS-PLATFORM TOOLING (macOS + Linux)
# ============================================================================

# --- PATH hygiene -----------------------------------------------------------
# Keep PATH unique so repeated prepends never create duplicates.
typeset -U PATH

# --- User tool directories --------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"     # uv, pipx, misc user binaries
export PATH="$HOME/.cargo/bin:$PATH"     # rustup / cargo
export PATH="$HOME/.config/tmux:$PATH"   # tmux-sessionizer

# --- Homebrew (Apple Silicon macOS, Intel macOS, Linuxbrew) -----------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# --- Homebrew completions: use a user-owned mirror --------------------------
# Some Homebrew installs are owned by another account (e.g. a shared Mac).
# compinit treats those files as insecure and asks [y/n] on every start, so
# copy them somewhere owned by this user and drop the original from fpath.
if [[ -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
  mkdir -p "$HOME/.zsh/completions"
  cp -Lf "$HOMEBREW_PREFIX"/share/zsh/site-functions/_* "$HOME/.zsh/completions/" 2>/dev/null
  fpath=(${fpath:#${HOMEBREW_PREFIX}/share/zsh/site-functions})
  fpath=("$HOME/.zsh/completions" $fpath)
fi

# --- nvm (cross-platform; prefer ~/.nvm, fall back to Homebrew) -------------
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
elif [[ -n ${HOMEBREW_PREFIX:-} && -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
fi

# --- Completion system (must run after fpath setup above) -------------------
autoload -Uz compinit && compinit
zinit cdreplay -q

# --- Cross-platform tool integrations ---------------------------------------
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

# --- Bun --------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Load after compinit so bun's script doesn't trigger its own compinit.
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"


# ============================================================================
# 3. PLATFORM-SPECIFIC SETUP
# ============================================================================

if [[ $OSTYPE == darwin* ]]; then
  # GNU tar: only needed for GNU-specific flags; BSD tar is the system default.
  [[ -d /opt/homebrew/opt/gnu-tar/libexec/gnubin ]] &&
    export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"

  # PostgreSQL client tools (Homebrew's libpq is keg-only).
  [[ -d /opt/homebrew/opt/libpq/bin ]] &&
    export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

  # WezTerm CLI; the GUI does not need this.
  [[ -d /Applications/WezTerm.app/Contents/MacOS ]] &&
    export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"

  # Homebrew LLVM is intentionally NOT on PATH: it shadows Apple clang,
  # which is the compiler that actually works on this machine.

elif [[ $OSTYPE == linux* ]]; then
  # Linux-specific paths go here (none needed right now).
  :
fi
