# Brewfile Curated List

> 최종 업데이트: 2026-03-02
> 이 파일은 실제 `Brewfile`(hook 자동 생성)과 별도로 관리되는 큐레이션 목록입니다.
> 불필요한 패키지 제거 가이드 및 카테고리 분류를 제공합니다.

## 제거 대상 (brew uninstall 필요)

아래 패키지를 `brew uninstall`하면 다음 커밋 시 hook이 Brewfile에서 자동 제거합니다.

### Taps (6개)

```bash
brew untap equalsraf/neovim-qt
brew untap omnisharp/omnisharp-roslyn
brew untap sst/tap
brew untap steipete/tap
brew untap subinium/tap
brew untap wimdeblauwe/ttcli
```

### Brew (21개)

```bash
brew uninstall autojump        # zoxide로 대체
brew uninstall diff-so-fancy   # git-delta로 통합
brew uninstall icdiff           # git-delta로 통합
brew uninstall macvim           # neovim으로 통합
brew uninstall neovim-qt        # neovim으로 통합
brew uninstall dust             # gdu로 통합
brew uninstall cocoapods        # iOS 미사용
brew uninstall ideviceinstaller # iOS 미사용
brew uninstall ios-deploy       # iOS 미사용
brew uninstall libimobiledevice # iOS 미사용
brew uninstall libusbmuxd       # iOS 미사용
brew uninstall kdoctor          # iOS/KMP 미사용
brew uninstall omnisharp-mono   # C# 미사용
brew uninstall aspell           # 에디터 내장 대체
brew uninstall brightness       # macOS 시스템 조절
brew uninstall doxx             # 미사용
brew uninstall mole             # ssh -L 대체
brew uninstall up               # 미사용
brew uninstall xclip            # macOS pbcopy/pbpaste
brew uninstall leveldb          # 미사용 DB
brew uninstall caddy            # 미사용 웹서버
```

### Casks (2개)

```bash
brew uninstall --cask fig          # Claude Code로 대체
brew uninstall --cask mactex-no-gui # LaTeX 미사용
```

---

## 유지 패키지 (카테고리별)

### Taps

```ruby
tap "f/textream"
tap "felixkratz/formulae"
tap "hamed-elfayome/claude-usage"
tap "homebrew/bundle"
tap "homebrew/cask-fonts"
tap "homebrew/services"
tap "jesseduffield/lazygit"
tap "jetbrains/utils"
tap "jstkdng/programs"
tap "koekeishiya/formulae"
tap "maciejwalkowiak/brew"
tap "nikitabobko/tap"
tap "njbrake/aoe"
tap "osx-cross/arm"           # QMK 크로스 컴파일용
tap "osx-cross/avr"           # QMK 크로스 컴파일용
tap "oven-sh/bun"
tap "qmk/qmk"
tap "testingisdocumenting/brew"
```

### Shell & Terminal

```ruby
brew "bat"
brew "broot"
brew "cheat"
brew "eza"
brew "fzf"
brew "lsd"
brew "navi"
brew "powerlevel10k"
brew "terminal-notifier"
brew "thefuck"
brew "tlrc"
brew "tmux"
brew "tree"
brew "vivid"
brew "zoxide"
brew "zsh"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
```

### Editors & Language Servers

```ruby
brew "ctags"
brew "jdtls"
brew "lua-language-server"
brew "markdown-oxide"
brew "neovim"
brew "opencode"
brew "yaml-language-server"
brew "jetbrains/utils/kotlin-lsp"
```

### Git & Version Control

```ruby
brew "bfg"
brew "commitizen"
brew "gh"
brew "git"
brew "git-delta"
brew "git-filter-repo"
brew "git-lfs"
brew "git-machete"
brew "gitleaks"
brew "lazygit"
```

### Languages & Runtimes

```ruby
# Java
brew "gradle"
brew "maven"
brew "openjdk@21"

# Go
brew "go"

# Ruby
brew "rbenv"
brew "ruby"
brew "ruby-build"

# PHP
brew "php"

# Rust
brew "rust"
brew "rust-analyzer"

# Lua
brew "lua"
brew "luajit"
brew "luarocks"

# Python
brew "py3cairo"
brew "pyenv"
brew "pyenv-virtualenv"
brew "scipy"

# Node/JS
brew "oven-sh/bun/bun"

# Package managers
brew "pipx"
brew "uv"
```

### Build & Dev Tools

```ruby
brew "coreutils"
brew "docker"
brew "flock"
brew "gawk"
brew "go-task"
brew "stow"
brew "maciejwalkowiak/brew/just"
brew "njbrake/aoe/aoe"
brew "testingisdocumenting/brew/webtau"
```

### CLI Utilities

```ruby
# Search
brew "ast-grep"
brew "fd"
brew "grex"
brew "ripgrep"
brew "ripgrep-all"

# Data
brew "curl"
brew "glow"
brew "jq"
brew "llm"
brew "watch"
brew "wget"

# HTTP
brew "httpie"
brew "httpstat"
brew "hurl"
```

### File & Disk Tools

```ruby
brew "duf"
brew "gdu"
brew "lnav"
brew "pngpaste"
brew "trash"
brew "truncate", link: false
brew "unar"
brew "yazi"
brew "jstkdng/programs/ueberzugpp"
```

### Network & Cloud

```ruby
brew "aws-google-auth"
brew "awscli"
brew "gping"
brew "jira-cli"
brew "keychain"
brew "saml2aws"
```

### Database

```ruby
brew "h2"
brew "mysql-client"
brew "postgresql@14"
brew "redis"
brew "tokyo-cabinet"
```

### Media & Documents

```ruby
brew "ffmpeg"
brew "ffmpegthumbnailer"
brew "ghostscript"
brew "graphicsmagick"
brew "graphviz"
brew "imagemagick"
brew "mdbook"
brew "pandoc"
brew "yt-dlp"
```

### System Monitoring

```ruby
brew "asitop"
brew "bottom"
brew "htop"
```

### Window Management & UI

```ruby
brew "felixkratz/formulae/borders"
brew "felixkratz/formulae/sketchybar"
brew "koekeishiya/formulae/skhd"
brew "qmk/qmk/qmk"
```

### Fonts (Cask)

```ruby
cask "font-batang"
cask "font-carrois-gothic"
cask "font-meslo-lg-nerd-font"
cask "font-sarasa-gothic"
cask "font-sf-pro"
```

### Desktop Applications (Cask)

```ruby
cask "claude-code"
cask "devtoys"
cask "ghostty"
cask "gureumkim"
cask "hammerspoon"
cask "keycastr"
cask "ngrok"
cask "orbstack"
cask "qlmarkdown"
cask "qmk-toolbox"
cask "rectangle"
cask "sf-symbols"
cask "wkhtmltopdf"
cask "youtype"
cask "zed"
cask "f/textream/textream"
cask "hamed-elfayome/claude-usage/claude-usage-tracker"
cask "nikitabobko/tap/aerospace"
cask "jordanbaird-ice"
```

### Go & Cargo Packages

```ruby
go "github.com/danielmiessler/fabric"
go "github.com/danielmiessler/fabric/plugins/tools/to_pdf"
cargo "agf"
cargo "cargo-generate"
cargo "create-tauri-app"
cargo "obsidian-lsp"
```
