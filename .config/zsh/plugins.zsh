# ================================
# ⚡ POWERLEVEL10K INSTANT PROMPT
# MUST BE FIRST LINE
# ================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ================================
# ZINIT BOOTSTRAP (silent)
# ================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d $ZINIT_HOME/.git ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" >/dev/null 2>&1
fi

source "${ZINIT_HOME}/zinit.zsh"

# ================================
# COMPLETION INIT (early + cached)
# ================================
autoload -Uz compinit

# Use cache for speed
if [[ -f ~/.zcompdump ]]; then
  compinit -C
else
  compinit
fi

# ================================
# ⚡ PLUGINS (lazy + silent)
# ================================

# Powerlevel10k
zinit ice depth=1 silent
zinit light romkatv/powerlevel10k

# Autosuggestions
zinit ice wait"0a" silent atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# History search
zinit ice wait"0b" silent
zinit light zsh-users/zsh-history-substring-search

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# zoxide
zinit ice wait"1" silent as"program" from"gh-r"
zinit light ajeetdsouza/zoxide

# fzf-tab
zinit ice wait"1" silent
zinit light Aloxaf/fzf-tab

# zsh-completions (quiet)
zinit ice wait"1" silent
zinit light zsh-users/zsh-completions

# ================================
# MUST BE LAST
# ================================
zinit ice wait"0c" silent
zinit light zsh-users/zsh-syntax-highlighting

# ================================
# LOAD P10K CONFIG (no dotfiles)
# ================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
