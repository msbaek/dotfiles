# Homebrew (architecture-agnostic: /opt/homebrew on arm64, /usr/local on Intel)
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

export PATH=$HOME/bin:$PATH

# Completion system (cached - only full rebuild once per day)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# zsh-autosuggestions
source "$HOMEBREW_PREFIX"/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source ~/.zsh.after/msbaek.zsh
source ~/.zsh.after/ktown4u.zsh
source ~/.zsh.after/cw.zsh
source ~/.zsh.after/cj.zsh
source ~/.zsh.after/gj.zsh
source ~/.zsh.after/herdr-automatic-rename.zsh

# fnm (Fast Node Manager) — prebuilt node; replaces nvm/brew node (brew node has no Intel bottle,
# so a brew upgrade of simdjson/simdutf breaks the source-built binary; see memory 2026-11-07)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

alias tm='task-master'
alias taskmaster='task-master'

update-node-lts() {
    echo "Updating to latest LTS..."
    fnm install --lts
    fnm default lts-latest
    fnm use default
    echo "Node.js updated to: $(node --version)"
}

update-claude-code() {
    echo "Updating Claude Code..."
    npm update -g @anthropic-ai/claude-code
    echo "Claude Code updated to: $(claude --version)"
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

export EDITOR="nvim"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000

[ -f ~/.rm-safely ] && source ~/.rm-safely

# agf - AI Agent Session Finder
command -v agf >/dev/null 2>&1 && eval "$(agf init zsh)"

# Private environment variables
[ -f ~/dotfiles-private/.env.ktown4u ] && source ~/dotfiles-private/.env.ktown4u
[ -f ~/dotfiles-private/.env.github ] && source ~/dotfiles-private/.env.github

# Shell GPT with Cerebras AI
ai() {
  OPENAI_API_KEY="$CEREBRAS_API_KEY" sgpt -s "$*"
}
# zsh-syntax-highlighting (must be last)
source "$HOMEBREW_PREFIX"/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt — initialized in ~/.zsh.after/msbaek.zsh (with STARSHIP_CONFIG)


# Mole shell completion
if output="$(mole completion zsh 2>/dev/null)"; then eval "$output"; fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
