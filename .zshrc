export PATH=$HOME/bin:$PATH

# Completion system (cached - only full rebuild once per day)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# zsh-autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

source ~/.zsh.after/msbaek.zsh
source ~/.zsh.after/ktown4u.zsh

# NVM (lazy load - only loads when node/npm/nvm is first used)
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

alias tm='task-master'
alias taskmaster='task-master'

update-node-lts() {
    echo "Updating to latest LTS..."
    nvm install --lts
    nvm alias default lts/\*
    nvm use default
    echo "Node.js updated to: $(node --version)"
}

update-claude-code() {
    echo "Updating Claude Code..."
    npm update -g @anthropic-ai/claude-code
    echo "Claude Code updated to: $(claude --version)"
}

alias add_serena='~/bin/add-serena.sh'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

export EDITOR="nvim"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000

source "~/.rm-safely" >/dev/null 2>&1

# agf - AI Agent Session Finder
eval "$(agf init zsh)"

# Private environment variables
[ -f ~/dotfiles-private/.env.ktown4u ] && source ~/dotfiles-private/.env.ktown4u
[ -f ~/dotfiles-private/.env.github ] && source ~/dotfiles-private/.env.github

# Shell GPT with Cerebras AI
ai() {
  OPENAI_API_KEY="$CEREBRAS_API_KEY" sgpt -s "$*"
}

# Atuin - Shell history manager
eval "$(atuin init zsh)"

# zsh-syntax-highlighting (must be last)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt
eval "$(starship init zsh)"
