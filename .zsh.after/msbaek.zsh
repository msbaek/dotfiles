export PATH=~/bin:$PATH

fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/usr/local/share/zsh/site-functions $fpath)

export LDFLAGS="-L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"

export M2_HOME=/usr/local/opt/maven/libexec
export GRADLE_HOME=/usr/local/opt/gradle/libexec

export MAVEN_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=4000,server=y,suspend=n"

alias greset='git add .; git reset --hard HEAD'

# rbenv
# eval "$(rbenv init - zsh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$PATH:/Users/msbaek/icloud/bin"

export PATH=":$PATH:/Users/msbaek/bin/ijhttp/"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# start of alias expanding #
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/globalias/globalias.plugin.zsh
#
globalias() {
   # Get last word to the left of the cursor:
   # (z) splits into words using shell parsing
   # (A) makes it an array even if there's only one element
   local word=${${(Az)LBUFFER}[-1]}
   if [[ $GLOBALIAS_FILTER_VALUES[(Ie)$word] -eq 0 ]]; then
      zle _expand_alias
      zle expand-word
   fi
   zle self-insert
}
zle -N globalias

alias mci="mvn clean install"
alias mcr="mvn clean spring-boot:run"

export ZEPPELIN_HOME="/usr/local/zeppelin"
# export PYSPARK_PYTHON=python3
# export SPARK_HOME="/opt/homebrew/Cellar/apache-spark/3.3.1/libexec"
export TOMCAT_HOME="/usr/local/apache-tomcat-8.5.64"
alias sshadd='ssh-add ~/Documents/hminter-VPN/hmmall-keypair.pem'
alias listening-port='sudo lsof -PiTCP -sTCP:LISTEN'
alias pid-by-port='sudo lsof -i TCP:'

alias brewu='brew upgrade; brew cleanup'
alias ta='tmux attach'
set -o vi

alias vi='nvim'
alias gs='git status'
alias gl='git log'
alias find_wifi_pwd='security find-generic-password -wa '

alias cat='bat --plain --wrap character'
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'

if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

export TT="zzz"
export PATH="$HOME/.local/bin:$PATH"

export OH_MY_ZSH=/users/msbaek/.oh-my-zsh/
export ZSH_THEME="dracula"

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export HOMEBREW_PREFIX=$(brew --prefix)

eval "$(git machete completion zsh)"  # or, if it doesn't work:
source <(git machete completion zsh)

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

#-- Use fd instead of fzf -
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
#- The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash, zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory complet↓ion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source ~/fzf-git.sh/fzf-git.sh

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# export BAT_THEME=Dracula
export BAT_THEME=tokyonight_night

# alias ll='exa -l -a -s modified -r --git'
alias ll='lsd -aFlht'
alias ls='eza --color=always --long --git --icons=always --no-user --no-permissions -s modified'
alias fdm='fd --hidden --no-ignore'
alias rgm='rg --no-ignore --hidden'
# ---- TheFuck ---- 
# thefuck alias
eval $(thefuck --alias)
eval $(thefuck --alias fk)

# -- Zoxide (better cd) 
eval "$(zoxide init zsh)"

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history 
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# alias ls="eza --color=always --long --no-filesize --icons=always --no-time --no-user --no-permissions"
#alias ls="eza --color=always --long --icons=always --no-user --no-permissions"
alias ls="eza --color=always --icons=always -a -1 --git"

export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
eval "$(rbenv init -)"

alias jhkeycloakup='docker-compose -f src/main/docker/keycloak.yml up -d'

export PATH="/opt/homebrew/Caskroom/flutter/3.7.9/flutter/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Starship
# Not sure if counts a CLI tool, because it only makes my prompt more useful
# https://starship.rs/config/#prompt
if command -v starship &>/dev/null; then
  export STARSHIP_CONFIG=$HOME/github/dotfiles-latest/starship-config/active-config.toml
  eval "$(starship init zsh)" >/dev/null 2>&1
fi
