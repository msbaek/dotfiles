export PATH=~/bin:$PATH

fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/usr/local/share/zsh/site-functions $fpath)

export LDFLAGS="-L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"

export M2_HOME=/usr/local/opt/maven/libexec
export GRADLE_HOME=/usr/local/opt/gradle/libexec

export MAVEN_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=4000,server=y,suspend=n"


# rbenv
# eval "$(rbenv init - zsh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$PATH:$HOME/icloud/bin"

export PATH=":$PATH:$HOME/bin/ijhttp/"

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

export ZEPPELIN_HOME="/usr/local/zeppelin"
# export PYSPARK_PYTHON=python3
# export SPARK_HOME="/opt/homebrew/Cellar/apache-spark/3.3.1/libexec"
export TOMCAT_HOME="/usr/local/apache-tomcat-8.5.64"
set -o vi


# alias cat='bat --plain --wrap character'
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'

if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

export PATH="$HOME/.local/bin:$PATH"

export OH_MY_ZSH=$HOME/.oh-my-zsh/
export ZSH_THEME="dracula"

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export HOMEBREW_PREFIX=$(brew --prefix)

eval "$(git machete completion zsh)"  # or, if it doesn't work:
source <(git machete completion zsh)

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# --- setup fzf theme ---
# Light mode colors (GitHub Light theme inspired)
fg="#24292f"
bg="#ffffff"
bg_highlight="#f6f8fa"
purple="#8250df"
blue="#0969da"
cyan="#1f883d"

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
# export BAT_THEME=tokyonight_night
export BAT_THEME=GitHub

# vivid - LS_COLORS generator for better lsd/eza colors on light themes
export LS_COLORS="$(vivid generate one-light)"

# duf - disk usage with light theme
# Using function instead of alias to allow passing arguments
duf() {
  command duf --theme light "$@"
}

# alias ll='exa -l -a -s modified -r --git'
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

export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
eval "$(rbenv init -)"


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

# Golang environment variables
export GOROOT=$(brew --prefix go)/libexec
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH

# unalias gsd

export AWS_PROFILE=default
# export ANTHROPIC_MODEL='us.anthropic.claude-sonnet-4-20250514-v1:0'
# export DISABLE_PROMPT_CACHING=0
FUNCNEST=100

export ENABLE_LSP_TOOLS=1
# 클로드 코드에서 MCP를 설정만 하더라도 토큰을 잡아먹어
# 실제 일하는데 필요한 컨텍스트 용량을 잠식한다는 문제가 있습니다.
# 예를들면, playwright, next-devtools, serena 정도만 설정해도 4만 토큰정도 사용하게 되는데
# 시스템 프롬프트가 4.5k토큰을 쓴다는걸 감안하면 꽤 큰 용량입니다.
# 이에, 클로드 코드에서 동적으로 MCP를 로딩하는 기능을 잠수함 출시했네요.
# 환경변수에 `ENABLE_TOOL_SEARCH=true`를 설정하는 것으로 관련 기능이 활성화 되며,
# 활성화 이후 `/context`로 확인해 보면 MCP tools 항목이 사라진 것을 볼 수 있습니다.
# https://github.com/anthropics/claude-code/issues/12836
export ENABLE_TOOL_SEARCH=true
export VAULT_ROOT=$HOME/DocumentsLocal/msbaek_vault/

alias rm='trash'
alias greset='git add .; git reset --hard HEAD'
alias ll='lsd -aFlht'
alias ls='eza --color=always --long --git --icons=always --no-user --no-permissions -s modified'
alias fdm='fd --hidden --no-ignore'
alias rgm='rg --no-ignore --hidden'
alias brewu='brew upgrade; brew cleanup'
alias ta='tmux attach'
alias vi='nvim'
alias gl='git log'
# Headless mode aliases
alias cld='claude --dangerously-skip-permissions --teammate-mode tmux'
alias cc-commit='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit" --allowedTools "Bash,Read,Grep"'
alias cc-push='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit --push" --allowedTools "Bash,Read,Grep"'

alias d2h='diff2html -s side'

alias gdum='gdu -h -d 1'
alias agfu='cargo install --git https://github.com/subinium/agf.git'
alias find-largest-file='sudo du -a * | sort -r -n'
alias listening-port='sudo lsof -PiTCP -sTCP:LISTEN'
alias pid-by-port='sudo lsof -i TCP:'
alias find_wifi_pwd='security find-generic-password -wa '


# ── ~/bin migrated functions ──

# Show all local IP addresses (loopback 제외)
get_my_ip() {
  ifconfig | grep "inet " | grep -v 127.0.0.1
}

# 클립보드 텍스트의 줄 순서를 뒤집기 (pbpaste → 역순 → pbcopy)
reverse_lines() {
  pbpaste | awk '1 {line[NR] = $0} END {for (i=NR; i>0; i--) print line[i]}' | pbcopy
}

# fzf로 현재 디렉토리의 파일을 탐색하며 미리보기
prev() {
  find . -type f | fzf --ansi --preview 'less {}'
}

# 지정 포트를 점유 중인 프로세스를 강제 종료. usage: kill_by_port 8080
kill_by_port() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
}

# 현재 변경사항 버리고, main pull 후 지정 브랜치도 pull. usage: pull_br feature-branch
pull_br() {
  git add . ; git reset --hard HEAD; git checkout main; git pull; git checkout $1; git pull
}

# 파일의 들여쓰기 기반 복잡도 측정. usage: indent_complexity MyClass.java
indent_complexity() {
  java -jar $HOME/git/lib/indent-complexity-proxy/target/indent-complexity-proxy-0.2.0-standalone.jar $1
}

# 패턴으로 git 브랜치를 fuzzy 검색 후 checkout. usage: fsb feature
fzf-checkout() {
  local pattern=$*
  local branches branch
  branches=$(git branch --all | awk 'tolower($0) ~ /'"$pattern"'/') &&
  branch=$(echo "$branches" |
          fzf-tmux -p --reverse -1 -0 +m) &&
  if [ "$branch" = "" ]; then
      echo "[$0] No branch matches the provided pattern"; return;
  fi;
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fzf로 git log를 인터랙티브 탐색. enter=상세보기, ctrl-o=checkout
fzf-gl() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort --preview \
         'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1 ; }; f {}' \
      --header "enter to view, ctrl-o to checkout" \
      --bind "q:abort,ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:become:(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs git checkout)" \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" --preview-window=right:60%
}

# git 히스토리에서 한 커밋 뒤로 이동 (변경사항 초기화 후 부모 커밋으로 checkout)
unalias gb
gb() {
  git checkout .
  git clean -fd
  git checkout $(git log --pretty=%H --parents -n 2 | tail -n 1)
}

# git 히스토리에서 한 커밋 앞으로 이동. usage: gf [target-branch] (기본: main)
unalias gf
gf() {
  local BR
  if [ $# -eq 1 ]; then
      BR=$1
  fi
  BR=${BR:-main}
  echo "Checking out forwards from $BR"
  git checkout .
  git clean -fd
  git checkout $(git log --reverse --pretty=%H --ancestry-path HEAD..$BR | head -n 1)
}

# 터미널에 Matrix 스타일 텍스트 비 애니메이션
matrix() {
  while true; do
    echo $(tput lines) $(tput cols) $(( RANDOM % $(tput cols) )) $(printf "\U$(($RANDOM % 500))")
    sleep 0.05
  done | gawk '{
    a[$3]= 0;
    for (x in a){
      o=a[x];
      a[x]=a[x]+1;
      printf "\033[%s;%sH\033[2;32m%s",o,x,$4;
      printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,$4;
      if (a[x]>=$1){
        a[x]=0;
      }
    }
  }'
}
