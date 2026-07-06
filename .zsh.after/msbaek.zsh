export PATH=~/bin:$PATH

fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/usr/local/share/zsh/site-functions $fpath)

export LDFLAGS="-L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"

export M2_HOME=/usr/local/opt/maven/libexec
export GRADLE_HOME=/usr/local/opt/gradle/libexec

# export MAVEN_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=4000,server=y,suspend=n"


# rbenv
# eval "$(rbenv init - zsh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$PATH:$HOME/icloud/bin"

export PATH=":$PATH:$HOME/bin/ijhttp/"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

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
export DISABLE_AUTOUPDATER=1

# rm을 trash로 대체. 플래그(-rf 등)는 무시하고 파일만 휴지통으로 이동
rm() {
  local args=()
  for arg in "$@"; do
    [[ "$arg" == -* ]] || args+=("$arg")
  done
  if (( ${#args[@]} > 0 )); then
    command trash "${args[@]}"
  fi
}
alias greset='git add .; git reset --hard HEAD'
alias pkm='bash ~/DocumentsLocal/msbaek_vault/.claude/pkm/dashboard.sh'
alias cc-dashboard='python3 ~/.claude/bin/generate-cc-dashboard.py'

# ── Local LLM hardware checker (npx: no global install needed) ──
alias llm-hw='npx llm-checker hw-detect'
# usage: llm-rec [coding|talking|reasoning|multimodal]  default=coding
llm-rec() { npx llm-checker recommend --category "${1:-coding}"; }

# env Plan Harness — project-scoped plan lifecycle manager
alias env-plan='_env_plan_router'

_env_plan_router() {
  local sub="${1:-dashboard}"
  shift 2>/dev/null || true
  local project_root
  project_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "❌ env-plan: not in a git repository"
    return 1
  }
  local harness="$project_root/.claude/env"
  if [[ ! -d "$harness" ]]; then
    echo "❌ env-plan: no .claude/env/ harness found in $project_root"
    return 1
  fi
  case "$sub" in
    dashboard|"")  bash "$harness/dashboard.sh" ;;
    measure)       bash "$harness/measure/plan-status.sh" ;;
    gc)            bash "$harness/gc/plan-archive.sh" ;;
    drop)          bash "$harness/gc/plan-archive.sh" --topic "${1:-}" ;;
    alert)         bash "$harness/alert.sh" ;;
    *)             echo "Usage: env-plan [dashboard|measure|gc|drop <topic>|alert]" ;;
  esac
}

# Format-changing aliases — interactive 셸에서만 적용.
# non-interactive(스크립트·Claude Code Bash 등)에서는 진짜 ls/ll 이 보여야 출력 파싱이 안전.
if [[ -o interactive ]]; then
  alias ll='lsd -aFlht'
  alias ls='eza --color=always --long --git --icons=always --no-user --no-permissions -s modified'
fi
alias fdm='fd --hidden --no-ignore'
alias rgm='rg --no-ignore --hidden'
alias brewu='brew upgrade; brew cleanup'
alias ta='tmux attach -t work'
alias tk='tmux kill-server'

# fzf로 tmux session 선택 → 전환(tmux 안) 또는 attach(밖). 새 이름 입력 시 생성.
ts() {
  local session
  session=$(tmux list-sessions -F '#S' 2>/dev/null | fzf \
    --prompt="tmux session> " --height=40% --reverse \
    --preview 'tmux list-windows -t {} -F "#I: #W"' \
    --print-query | tail -1)
  [[ -z "$session" ]] && return

  # 없는 세션 이름이면 detached로 생성 (=exact 매칭 — has-session -t 는 prefix/fnmatch
  # 매칭이라 새 이름이 기존 세션의 접두사면 기존에 오인 매칭됨. '=' 로 정확 일치만 인정)
  tmux has-session -t "=$session" 2>/dev/null || tmux new-session -d -s "$session"

  # tmux 안이면 switch-client, 밖이면 attach (=exact 로 대상 고정)
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "=$session"
  else
    tmux attach -t "=$session"
  fi
}

alias vi='nvim'
alias gs='git status'
alias gl='git log'
alias lg='lazygit'
# hunk diff with persistent theme (hunk 0.16 has no theme persistence; --theme must follow the subcommand)
alias hd='hunk diff --theme github-light-high-contrast'
# Headless mode aliases
alias cld='claude --dangerously-skip-permissions --teammate-mode tmux'
# alias hcld='ANTHROPIC_BASE_URL="http://127.0.0.1:8787" claude "$@"'

# alias cld='$HOME/.local/bin/claude agents'

# claude headless /commit 실행 (teammate-mode tmux pane에서)
alias cc-commit='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit" --allowedTools "Bash,Read,Grep"'
# temp 파일 기반 한글 안전 commit (--no-verify). /tmp/commit_msg.txt 필요
alias cc-commit-only='git commit --no-verify -F /tmp/commit_msg.txt'
alias cc-push='claude --dangerously-skip-permissions --teammate-mode tmux -p "/commit --push" --allowedTools "Bash,Read,Grep"'

# sub-agent 모델 감사 (cwd/branch/첫 task 요약 포함). -f BO-query / --last 20 등 인자 전달
cc-model() { python3 "$HOME/.claude/bin/check-subagent-model.py" "$@"; }

# Agent teams(tmux): 완료(idle)된 teammate pane 정리. -n dry-run / -a 전체
alias cct='~/.claude/bin/cc-team-cleanup'

alias d2h='diff2html -s side'

# ktown4u-groupware Python CLI venv 활성화 (ktown4u-gw 명령 사용)
alias gw='source ~/git/kt4u/ktown4u-groupware-tools/.venv/bin/activate && ktown4u-gw menu'
alias gdum='gdu -h -d 1'
alias agfu='cargo install --git https://github.com/subinium/agf.git'
alias find-largest-file='du -ah * | sort -rn'
alias find_mac_addr="ifconfig en0 | grep ether | awk '{print \$2}'"
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

# 이름으로 프로세스 강제 종료. usage: kill_by_name playwright-mcp
kill_by_name() {
  if [ -z "$1" ]; then
    echo "Usage: kill_by_name <process-name>"; return 1
  fi
  pkill -9 -f "$1"
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
fsb() {
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
fshow() {
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
gb() {
  git checkout .
  git clean -fd
  git checkout $(git log --pretty=%H --parents -n 2 | tail -n 1)
}

# git 히스토리에서 한 커밋 앞으로 이동. usage: gf [target-branch] (기본: main)
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

# 현재 디렉토리의 디스크 여유 공간 표시 (GB/MB)
disk-free() {
  df -k . | tail -1 | awk '{free=$4; printf "Free: %.2f GB (%.2f MB)\n", free/1024/1024, free/1024}'
}

# ── Memory ──

# 여유 메모리를 GB 단위로 출력.
# free(즉시 가용) + inactive(재사용 가능) = usable. compressed가 크면 메모리 압박 중.
memfree() {
  local page=16384
  local stats
  stats=$(vm_stat)
  local free inactive compressed wired total
  free=$(echo "$stats"       | awk '/Pages free/                 {gsub(/\./,"",$NF); print $NF}')
  inactive=$(echo "$stats"   | awk '/Pages inactive/             {gsub(/\./,"",$NF); print $NF}')
  compressed=$(echo "$stats" | awk '/Pages stored in compressor/ {gsub(/\./,"",$NF); print $NF}')
  wired=$(echo "$stats"      | awk '/Pages wired down/           {gsub(/\./,"",$NF); print $NF}')
  total=$(sysctl -n hw.memsize)
  python3 -c "
p=$page; f=$free; i=$inactive; c=$compressed; w=$wired; t=$total
gb=lambda n: n*p/1024**3
tg=gb(t/p)
print(f'Total       {gb(t/p):5.1f} GB')
print(f'Free        {gb(f):5.2f} GB  ({gb(f)/tg*100:.1f}%)  — immediately available')
print(f'Inactive    {gb(i):5.2f} GB              — reclaimable (counts as usable)')
print(f'Usable      {gb(f+i):5.2f} GB  ({gb(f+i)/tg*100:.1f}%)  — free + inactive')
print(f'Compressed  {gb(c):5.1f} GB              — memory pressure indicator')
print(f'Wired       {gb(w):5.2f} GB              — OS kernel, not reclaimable')
"
}

# 메모리 "압박"을 진단한다. memfree(여유 관점)의 짝 — 확보가 필요한지/무엇을 줄일지 본다.
# swap used 가 크면 확보 필요 신호. 앱 단위 합산으로 helper 프로세스를 앱으로 묶어 회수 후보를 본다.
memcheck() {
  echo "── 압박 지표 (swap used 가 크면 확보 필요) ──"
  sysctl vm.swapusage | sed 's/^vm.swapusage:/Swap: /'
  top -l 1 -s 0 | awk '/PhysMem/ {sub(/PhysMem:/,""); print "Phys: "$0}'
  echo
  echo "── 앱 단위 합산 메모리 top 12 (회수 후보) ──"
  ps axo rss,comm | awk 'NR>1 {sub(/.*\//,"",$2); m[$2]+=$1}
    END {for (a in m) printf "%7.0f MB  %s\n", m[a]/1024, a}' | sort -rn | head -12
}

# 현재 떠 있는 claude 세션을 그룹별로 분류해 본다(★=현재 세션, 절대 보호).
#   ccps        조사만 (읽기 전용, 안전)
#   ccps -k     정리 후보를 dry-run 으로 표시 (_cc_stale_review 기준). 실제 kill 은 안 함.
ccps() {
  local self=$$ sp=""
  while [ "$self" -gt 1 ]; do
    [ "$(ps -o comm= -p "$self" 2>/dev/null | sed 's#.*/##')" = claude ] && { sp=$self; break; }
    self=$(ps -o ppid= -p "$self" 2>/dev/null | tr -d ' '); [ -z "$self" ] && break
  done
  echo "   PID     GROUP        ELAPSED    RSS      TTY      (★=현재 세션, 보호)"
  ps -axo pid=,ppid=,tty=,etime=,rss=,comm= | awk -v sp="$sp" '
    {c=$NF; sub(/.*\//,"",c)}
    c=="claude" {
      grp = ($2==1) ? "orphan" : ($3=="??" ? "background" : "interactive")
      printf "%s %-7s %-12s %-10s %6.0fMB  %s\n", ($1==sp?"★":" "), $1, grp, $4, $5/1024, $3
    }' | sort -k2
  [ "$1" = "-k" ] && _cc_stale_review "$sp"
}

# TODO(human): claude 정리 후보(stale)를 판단해 dry-run 으로 출력.
#   인자 $1 = 보호할 현재 세션 PID (절대 후보에서 제외).
#   ccps 출력의 3그룹을 떠올려라 — interactive(열어둔 세션)/background(MCP·headless)/orphan(고아).
#   "정리해도 되는 잔존"의 기준은 당신 워크플로우에 달려 있다:
#     · orphan(PPID 1) 만 후보로? · background 중 etime 오래된 것? · idle 임계값?
#   ps -axo pid=,ppid=,etime=,comm= 로 claude 행을 돌며 후보를 고르고,
#   "would kill: <pid> (<group>, idle <etime>)" 형태로 출력만 하라.
#   실제 kill 은 절대 하지 말 것 — 사용자가 표시된 PID 로 직접 kill <pid>.
_cc_stale_review() {
  local keep="$1"
  : # TODO(human)
}

# ── Disk cleanup (OrbStack / Docker / Xcode) ──
# 출처: vault 003-RESOURCES/TOOLS/OrbStack-디스크-용량-줄이기.md

# Docker 미사용 데이터 일괄 정리 (이미지/컨테이너/볼륨/빌드캐시). docker 가 확인 프롬프트 표시
alias docker-prune='docker system prune -a --volumes'
# Docker 디스크 사용량 분류 표시 (이미지/컨테이너/볼륨/빌드캐시별)
alias docker-df='docker system df'
# 미사용(unavailable) iOS 시뮬레이터 일괄 삭제
alias simctl-clean='xcrun simctl delete unavailable'
# OrbStack 완전 재시작으로 sparse 디스크 이미지 공간 회수 (prune 후 실행 권장)
alias orb-restart='orbctl stop && orbctl start'

# OrbStack 디스크 실제 사용량 확인. data.img(Linux+Docker)와 ~/.orbstack 차지 용량을 출력.
# 팀 ID(HUAQ24HBR6) 하드코딩 대신 *orbstack* glob 으로 portable 하게.
orb-usage() {
  du -sh ~/Library/Group\ Containers/*orbstack*/ 2>/dev/null
  du -sh ~/.orbstack/ 2>/dev/null
}

# ── Git repository health commands (https://news.hada.io/topic?id=28324) ──

# 최근 1년간 가장 많이 변경된 상위 20개 파일 출력. 변경 빈도와 버그 집중 영역 파악
git-churn() {
  git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
}

# 기여자별 커밋 수 순위 (merge 제외). 버스 팩터·지식 단절 위험 점검
git-contributors() {
  git shortlog -sn --no-merges
}

# fix/bug/broken 키워드 커밋에서 자주 수정된 상위 20개 파일. 취약 영역 식별
git-buggy-files() {
  git log -i -E --grep='\b(fix|fixed|fixes|bug|broken)\b' --name-only --format='' | sort | uniq -c | sort -nr | head -20
}

# 월별 커밋 수 추세. 팀 개발 동력·속도 변화 추적
git-timeline() {
  git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
}

# 최근 1년간 revert/hotfix/emergency/rollback 커밋 조회. 배포 안정성 평가
git-hotfixes() {
  git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
}

# ── html-anything (https://github.com/nexu-io/html-anything) ──

# html-anything 폴더로 이동
ha() {
  cd ~/git/ai-agent/html-anything || return 1
}

# html-anything dev 서버 기동 (Next.js Turbopack → http://localhost:3000)
hadev() {
  (cd ~/git/ai-agent/html-anything && pnpm dev "$@")
}

# ── Help ──

# cheatsheet 파일(~/.zsh.after/msbaek.cheats)을 fzf로 검색.
# 항목: alias / function / external CLI. Enter=커맨드라인 붙여넣기.
mshelp() {
  local file="$HOME/.zsh.after/msbaek.cheats"
  [[ -f "$file" ]] || { echo "[mshelp] not found: $file"; return 1 }
  local cmd
  cmd=$(awk -F'\t' '
    # $4(category)는 이름 옆 회색 태그로 표시. 같은 값 입력 시 fzf 가 그룹 필터.
    # macOS BSD awk 는 한글을 바이트로 세어 desc 뒤 우측정렬이 불가 → 카테고리는 좌측(이름 직후) 배치.
    function row(color, name, cat, desc) {
      printf "%s%-22s\033[0m \033[90m%-8s\033[0m %s\n", color, name, (cat != "" ? "[" cat "]" : ""), desc
    }
    /^#/ { next }
    NF < 3 { next }
    $1 == "a" { row("\033[33m", $2, $4, $3) }
    $1 == "f" { row("\033[36m", $2, $4, $3) }
    $1 == "e" { row("\033[32m", $2, $4, $3) }
  ' "$file" | fzf --ansi \
    --header="alias=yellow func=cyan ext=green │ [category] 검색=그룹 필터 │ Enter=붙여넣기" \
    --preview-window=hidden --reverse)
  if [[ -n "$cmd" ]]; then
    # 이름 컬럼(첫 22자) 추출 + ANSI 제거 + 우측 공백 trim. multi-word name(e.g. "mo clean") 지원
    local name=$(echo "$cmd" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-22 | sed 's/[[:space:]]*$//')
    print -z "$name"
  fi
}

# ── Headroom — Claude Code 컨텍스트 압축 proxy ──
# 데몬은 launchd(com.headroom.proxy)로 상시 기동(RunAtLoad + KeepAlive).
# hr = 데몬 제어 래퍼, hclaude = proxy 경유 실행 스위치.

# headroom 데몬 제어. usage: hr [status|start|stop|restart|log]
hr() {
  local sub="${1:-status}"
  local label="com.headroom.proxy"
  local plist="$HOME/Library/LaunchAgents/${label}.plist"
  local log="$HOME/Library/Logs/headroom-proxy.log"
  local domain="gui/$(id -u)"
  local url="http://127.0.0.1:8787"
  case "$sub" in
    status)
      local line=$(launchctl list | grep "$label")
      if [[ -z "$line" ]]; then
        echo "⏹  headroom: not loaded  (hr start 로 기동)"
        return 1
      fi
      local pid=$(echo "$line" | awk '{print $1}')
      if [[ "$pid" == "-" ]]; then
        echo "⏸  headroom: loaded but stopped"
      else
        echo "▶  headroom: running (PID $pid)"
        curl -s "$url/health" | python3 -c \
          'import sys,json; d=json.load(sys.stdin); print("   ready=%s  version=%s  uptime=%.0fs" % (d["ready"], d["version"], d["uptime_seconds"]))' \
          2>/dev/null || echo "   (health 아직 준비 안 됨 — warmup ~40s)"
      fi
      ;;
    start)
      # bootstrap = plist 재파싱(env 변경 반영). stop 직후 tear-down race 대비 retry+wait.
      local n=0
      until launchctl bootstrap "$domain" "$plist" 2>/dev/null; do
        (( ++n > 25 )) && { echo "❌ headroom: bootstrap 실패 (이전 job 정리 안 됨?)"; return 1; }
        sleep 0.2
      done
      echo "▶  headroom started"
      ;;
    stop)
      # KeepAlive=true 라 launchctl stop 은 즉시 재기동 → 완전 정지는 bootout.
      # bootout 이 0 을 반환해도 tear-down 은 비동기 → job 이 사라질 때까지 대기해야
      # 직후 hr start 의 bootstrap 이 'already in progress' 로 깨지지 않는다.
      launchctl bootout "$domain/$label" 2>/dev/null
      local n=0
      while launchctl print "$domain/$label" >/dev/null 2>&1; do
        (( ++n > 50 )) && break   # 최대 ~10s 대기 후 포기
        sleep 0.2
      done
      echo "⏹  headroom stopped"
      ;;
    restart)
      # 프로세스만 재시작 (이미 로드된 plist 사용 → env/plist 변경은 미반영).
      # 코드 무변경 재시작·hang 복구용. env 변경 반영은 hr stop 후 hr start.
      launchctl kickstart -k "$domain/$label" && echo "🔄 headroom restarted"
      ;;
    log)
      tail -f "$log"
      ;;
    update)
      # headroom 업그레이드 → offline 우회 온라인 prefetch(캐시 갱신) → 데몬 재기동.
      # 데몬(8787, offline)은 그대로 두고 임시 포트(8799)에 online 인스턴스만 띄워
      # 캐시를 채운다. plist(env) 자체를 바꾼 게 아니라면 hr restart 로 충분.
      echo "1/3) headroom 업그레이드..."
      pipx upgrade headroom-ai || echo "  (업그레이드 실패/스킵 — 계속 진행)"

      echo "2/3) offline 우회 온라인 prefetch (임시 포트 8799, 데몬은 계속 서비스 중)..."
      local pport=8799
      HF_HUB_OFFLINE=0 TRANSFORMERS_OFFLINE=0 \
        headroom proxy --port "$pport" >/tmp/headroom-prefetch.log 2>&1 &
      local ppid=$!

      # TODO(human): prefetch 완료(모델 다운로드 끝나 ready)를 감지하고 빠져나오기.
      #   - 신호 후보: http://127.0.0.1:$pport/health 의 "ready": true 를 폴링,
      #     또는 /tmp/headroom-prefetch.log 에서 ready/Started 흔적 감지.
      #   - 모델 다운로드는 수십 초~수 분 → 타임아웃을 넉넉히(예: 300초) 두고,
      #     완료되면 즉시 / 타임아웃이면 경고 후 루프 탈출.
      #   - 임시 프로세스 정리(kill)는 아래에서 하므로 여기서는 '대기'만 책임진다.

      kill "$ppid" 2>/dev/null; wait "$ppid" 2>/dev/null
      echo "3/3) 데몬 재기동 (새 캐시·바이너리 반영)..."
      hr restart && hr status
      ;;
    *)
      echo "Usage: hr [status|start|stop|restart|update|log]"
      return 1
      ;;
  esac
}

# Claude Code 를 headroom proxy 경유로 실행 (로그·JSON 세션 압축).
# 평소 코드 작업은 그냥 claude, 압축이 필요한 세션만 hclaude.
hclaude() {
  ANTHROPIC_BASE_URL="http://127.0.0.1:8787" claude "$@"
}
