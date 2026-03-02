# Homebrew 패키지 인덱스

> 최종 업데이트: 2026-03-02
> 총 패키지 수: 142개 (tap 19 + brew 106 + cask 17 + go 2 + cargo 4)

## Taps (Third-party Repositories)

| Tap | 설명 |
|-----|------|
| `f/textream` | Textream 앱 설치용 탭 |
| `felixkratz/formulae` | SketchyBar, Borders 등 macOS UI 도구 |
| `hamed-elfayome/claude-usage` | Claude 사용량 트래커 |
| `homebrew/bundle` | Brewfile 관리 (bundle dump/install) |
| `homebrew/cask-fonts` | 폰트 설치 지원 |
| `homebrew/services` | Homebrew 서비스 관리 (start/stop/restart) |
| `jesseduffield/lazygit` | LazyGit TUI Git 클라이언트 |
| `jetbrains/utils` | JetBrains 유틸리티 (Kotlin LSP 등) |
| `jstkdng/programs` | ueberzugpp (터미널 이미지 렌더링) |
| `koekeishiya/formulae` | skhd (키보드 단축키 데몬) |
| `maciejwalkowiak/brew` | just (make 대체 커맨드 러너) |
| `nikitabobko/tap` | AeroSpace (타일링 윈도우 매니저) |
| `njbrake/aoe` | aoe (Age of Empires 관련 도구) |
| `osx-cross/arm` | ARM 크로스 컴파일 툴체인 |
| `osx-cross/avr` | AVR 크로스 컴파일 툴체인 |
| `oven-sh/bun` | Bun JavaScript 런타임 |
| `qmk/qmk` | QMK 키보드 펌웨어 빌드 도구 |
| `testingisdocumenting/brew` | webtau (웹 테스팅 프레임워크) |

---

## Shell & Terminal

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `bat` | cat 대체, 구문 하이라이팅 지원 | `bat file.txt`, `--plain` 옵션으로 순수 출력 |
| `broot` | 디렉토리 탐색 TUI (fuzzy search + tree view) | `br`, 대량 파일 탐색 시 tree보다 빠름 |
| `cheat` | 커맨드 치트시트 조회 | `cheat tar`, `.config/cheat/` 커스텀 시트 추가 가능 |
| `eza` | ls 대체, Git 상태 + 아이콘 표시 | `eza --long --git --icons`, `alias ls='eza'` |
| `fzf` | 퍼지 파인더 (역방향 검색, Ctrl+R) | `vim $(fzf)`, `kill -9 $(ps aux \| fzf)` |
| `lsd` | ls deluxe, 디렉토리 트리 + 색상 | `lsd --tree --depth 2` |
| `navi` | 인터랙티브 치트시트 (fzf 기반) | `navi`, `Ctrl+G`로 실행 가능한 스니펫 선택 |
| `powerlevel10k` | Zsh 프롬프트 테마 (Git/Python/Node 상태 표시) | `.zshrc`에서 로드, `p10k configure` 초기 설정 |
| `terminal-notifier` | macOS 알림 전송 CLI | `terminal-notifier -message "Done" -title "Build"` |
| `thefuck` | 잘못 입력한 명령어 자동 수정 | `fuck` (alias `please`), ESC 두 번으로도 가능 |
| `tlrc` | tldr(Too Long; Didn't Read) Rust 구현, 간단한 예제 중심 man | `tlrc tar`, man보다 빠르고 직관적 |
| `tmux` | 터미널 멀티플렉서 (세션 분할/복원) | `tmux attach`, `Ctrl+B %`로 수직 분할 |
| `tree` | 디렉토리 트리 출력 | `tree -L 2 -I node_modules` |
| `vivid` | LS_COLORS 생성기 (테마 지원) | `export LS_COLORS=$(vivid generate molokai)` |
| `zoxide` | cd 대체, 방문 빈도 기반 점프 | `z dotf`, `zi` (인터랙티브 선택) |
| `zsh` | 기본 셸 (macOS 13+ 기본값) | `.zshrc`, `.zshenv`, `.zprofile` |
| `zsh-autosuggestions` | 명령어 자동 완성 제안 (히스토리 기반) | 회색 텍스트, `→` 키로 수락 |
| `zsh-syntax-highlighting` | 명령어 구문 하이라이팅 (실시간 오류 표시) | 빨강(오류)/녹색(정상) 색상 표시 |

---

## Editors & Language Servers

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `ctags` | 소스 코드 태그 생성 (함수/클래스 정의 점프) | `ctags -R .`, Vim에서 `Ctrl+]` 정의 이동 |
| `jdtls` | Java Language Server (Eclipse 기반) | Neovim LSP, IntelliSense/리팩토링/디버깅 |
| `lua-language-server` | Lua LSP (Neovim 설정 편집 시 필수) | `init.lua` 편집 시 자동 완성/타입 체크 |
| `markdown-oxide` | Markdown LSP (wikilink, frontmatter 지원) | Obsidian 스타일 `[[link]]` 자동 완성 |
| `neovim` | Vim 포크, LSP/TreeSitter 네이티브 지원 | `nvim`, `.config/nvim/`, LazyVim 설정 사용 |
| `opencode` | VS Code로 파일 열기 CLI | `opencode .` (Finder에서 현재 폴더 열기) |
| `yaml-language-server` | YAML LSP (Kubernetes/Docker Compose 등) | `docker-compose.yml` 편집 시 스키마 검증 |
| `kotlin-lsp` | Kotlin Language Server (JetBrains 공식) | Kotlin 파일 편집 시 LSP 지원 |

---

## Git & Version Control

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `bfg` | Git 히스토리 대용량 파일 제거 (filter-branch보다 빠름) | `bfg --delete-files secret.key repo.git` |
| `commitizen` | Conventional Commits 포맷 가이드 | `cz commit`, 대화형 커밋 메시지 작성 |
| `gh` | GitHub CLI (PR/Issue 관리) | `gh pr create`, `gh issue list` |
| `git` | 버전 관리 시스템 | `.gitconfig` 글로벌 설정 |
| `git-delta` | Git diff 출력 개선 (구문 하이라이팅) | `.gitconfig`에 `pager.diff = delta` 설정 |
| `git-filter-repo` | Git 히스토리 재작성 (filter-branch 대체) | `git filter-repo --path src/ --invert-paths` |
| `git-lfs` | Git Large File Storage (대용량 바이너리 관리) | `git lfs track "*.psd"` |
| `git-machete` | Git 브랜치 관계 시각화 | `git machete status`, 리베이스 순서 자동 계산 |
| `gitleaks` | Git 히스토리 secrets 스캔 | `gitleaks detect --verbose` |
| `lazygit` | Git TUI (브랜치/스테이징/커밋 관리) | `lazygit`, `Ctrl+A`로 파일 스테이징 |

---

## Languages & Runtimes

### Java

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `gradle` | Java 빌드 도구 (Kotlin DSL 지원) | `gradle build`, `gradlew` wrapper 사용 권장 |
| `maven` | Java 빌드 도구 (Spring Boot 기본) | `mvn clean install`, `settings.xml` 설정 |
| `openjdk@21` | OpenJDK 21 (LTS) | `java -version`, JAVA_HOME 환경변수 설정 필요 |

### Go

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `go` | Go 프로그래밍 언어 | `go run main.go`, `go mod tidy` |

### Ruby

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `rbenv` | Ruby 버전 관리자 | `rbenv install 3.2.0`, `rbenv global 3.2.0` |
| `ruby` | Ruby 인터프리터 | `ruby script.rb` |
| `ruby-build` | rbenv 플러그인 (Ruby 빌드 정의) | rbenv가 새 Ruby 버전 설치 시 사용 |

### PHP

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `php` | PHP 인터프리터 | `php -S localhost:8000` (내장 웹서버) |

### Rust

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `rust` | Rust 컴파일러 + Cargo | `cargo new project`, `cargo build --release` |
| `rust-analyzer` | Rust LSP (IDE 기능) | Neovim/VS Code에서 자동 완성/타입 체크 |

### Lua

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `lua` | Lua 인터프리터 | `lua script.lua` |
| `luajit` | Lua JIT 컴파일러 (Neovim 내부 사용) | `luajit -v` |
| `luarocks` | Lua 패키지 매니저 | `luarocks install luasocket` |

### Python

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `py3cairo` | Python Cairo 그래픽 라이브러리 | PDF/SVG 생성 스크립트 |
| `pyenv` | Python 버전 관리자 | `pyenv install 3.11.0`, `pyenv global 3.11.0` |
| `pyenv-virtualenv` | pyenv 가상환경 플러그인 | `pyenv virtualenv 3.11.0 myenv` |
| `scipy` | Python 과학 계산 라이브러리 | NumPy, SciPy, Pandas 의존성 |

### Node/JS

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `bun` | 초고속 JavaScript 런타임 (Node 대체) | `bun run dev`, `bun install` (npm보다 빠름) |

### Package Managers

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `pipx` | Python CLI 도구 격리 설치 | `pipx install black` (글로벌 오염 방지) |
| `uv` | Python 패키지 매니저 (pip 대체, Rust 기반) | `uv pip install requests` (pip보다 10~100배 빠름) |

---

## Build & Dev Tools

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `coreutils` | GNU 핵심 유틸리티 (macOS BSD 유틸 대체) | `gdate`, `gls`, `gwc` (g 접두사 사용) |
| `docker` | 컨테이너 런타임 CLI | `docker build -t app .`, OrbStack과 함께 사용 |
| `flock` | 파일 잠금 (스크립트 동시 실행 방지) | `flock /tmp/lock.file script.sh` |
| `gawk` | GNU awk (macOS awk보다 기능 많음) | `gawk '{print $1}'`, CSV 파싱 |
| `go-task` | Task runner (Makefile 대체, YAML 기반) | `task build`, `Taskfile.yml` 정의 |
| `stow` | 심볼릭 링크 관리 (dotfiles 배포) | `stow .` (현재 디렉토리를 `~/`에 심링크) |
| `just` | 커맨드 러너 (make 대체, 더 간단한 문법) | `just build`, `justfile` 정의 |
| `aoe` | Age of Empires 도구 (용도 불명) | - |
| `webtau` | 웹 API/UI 테스팅 프레임워크 | `webtau test.groovy` |

---

## CLI Utilities

### Search

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `ast-grep` | AST 기반 코드 검색/리팩토링 | `sg -p 'console.log($$$)' --lang js`, 구조적 검색 |
| `fd` | find 대체 (더 빠르고 직관적) | `fd '\.java$'`, `.gitignore` 자동 존중 |
| `grex` | 정규식 자동 생성 (예제 입력으로부터) | `grex '2024-01-01' '2024-12-31'` → `\d{4}-\d{2}-\d{2}` |
| `ripgrep` | grep 대체 (초고속, 재귀 검색 기본) | `rg 'TODO' --type java`, `.gitignore` 존중 |
| `ripgrep-all` | PDF/DOCX/ZIP 내부 검색 | `rga 'contract' documents/` |

### Data

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `curl` | HTTP 요청 CLI | `curl -X POST -d '{"key":"val"}' api.com` |
| `glow` | Markdown 터미널 렌더러 | `glow README.md`, 테마/페이저 지원 |
| `jq` | JSON 파싱/변환 | `curl api.com \| jq '.data[] \| .name'` |
| `llm` | LLM CLI (OpenAI/Anthropic API) | `llm "요약해줘" < article.txt` |
| `watch` | 명령어 주기적 실행 (변화 모니터링) | `watch -n 2 'ls -lh'` |
| `wget` | 파일 다운로드 (재개 지원) | `wget -c https://example.com/file.zip` |

### HTTP

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `httpie` | HTTP 클라이언트 (curl보다 직관적) | `http POST api.com name=John` |
| `httpstat` | HTTP 요청 시간 시각화 | `httpstat https://google.com` (DNS/TLS 시간 분석) |
| `hurl` | HTTP 테스트 러너 (파일 기반) | `hurl --test api.hurl`, CI/CD 통합 가능 |

---

## File & Disk Tools

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `duf` | df 대체, 디스크 사용량 시각화 | `duf`, 컬러풀한 테이블 출력 |
| `gdu` | 디스크 사용량 분석 TUI (ncdu보다 빠름) | `gdu ~`, 대용량 폴더 찾기 |
| `lnav` | 로그 파일 뷰어 (자동 포맷 감지) | `lnav /var/log/*.log`, SQL 쿼리 지원 |
| `pngpaste` | 클립보드 이미지 → PNG 저장 | `pngpaste screenshot.png` (Alfred 워크플로우에서 사용) |
| `trash` | rm 대체, 휴지통으로 이동 | `trash file.txt`, `alias rm='trash'` |
| `truncate` | 파일 크기 조절 (심링크 비활성화) | `truncate -s 100M file.bin` |
| `unar` | 압축 해제 (zip/rar/7z 통합) | `unar archive.rar`, 인코딩 자동 감지 |
| `yazi` | 터미널 파일 매니저 (이미지 프리뷰) | `yazi`, `hjkl` 네비게이션 |
| `ueberzugpp` | 터미널 이미지 렌더링 (yazi/lf 백엔드) | Yazi에서 이미지 미리보기 활성화 |

---

## Network & Cloud

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `aws-google-auth` | Google SSO로 AWS 인증 | `aws-google-auth` → 임시 크레덴셜 생성 |
| `awscli` | AWS CLI (S3/EC2/Lambda 관리) | `aws s3 ls`, `aws ec2 describe-instances` |
| `gping` | ping + 그래프 시각화 | `gping google.com`, 실시간 레이턴시 차트 |
| `jira-cli` | Jira 이슈 관리 CLI | `jira issue list`, `jira issue create` |
| `keychain` | SSH 키 관리 (자동 로드) | `.zshrc`에서 `eval $(keychain --eval id_rsa)` |
| `saml2aws` | SAML 기반 AWS 인증 | `saml2aws login`, 다중 계정 프로필 관리 |

---

## Database

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `h2` | Java 임베디드 DB (in-memory/file 모드) | Spring Boot 테스트용, `jdbc:h2:mem:testdb` |
| `mysql-client` | MySQL 클라이언트 (서버 제외) | `mysql -h host -u user -p` |
| `postgresql@14` | PostgreSQL 14 | `brew services start postgresql@14` |
| `redis` | 인메모리 키-값 저장소 | `brew services start redis`, `redis-cli` |
| `tokyo-cabinet` | DBM 라이브러리 (고성능 키-값 저장소) | 레거시 프로젝트 의존성 |

---

## Media & Documents

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `ffmpeg` | 동영상/오디오 변환/편집 | `ffmpeg -i input.mp4 -vcodec h264 output.mp4` |
| `ffmpegthumbnailer` | 동영상 썸네일 생성 | `ffmpegthumbnailer -i video.mp4 -o thumb.jpg` |
| `ghostscript` | PDF/PostScript 처리 | `gs -dNOPAUSE -sDEVICE=pdfwrite` |
| `graphicsmagick` | 이미지 변환 (ImageMagick 포크) | `gm convert -resize 50% in.jpg out.jpg` |
| `graphviz` | 그래프 시각화 (dot 언어) | `dot -Tpng graph.dot -o graph.png` |
| `imagemagick` | 이미지 변환/편집 CLI | `convert -resize 50% in.jpg out.jpg` |
| `mdbook` | Markdown → 정적 사이트 (Rust Book 스타일) | `mdbook build`, `mdbook serve` |
| `pandoc` | 범용 문서 변환 (Markdown/LaTeX/DOCX) | `pandoc input.md -o output.pdf` |
| `yt-dlp` | YouTube/비디오 다운로더 (youtube-dl 포크) | `yt-dlp -f 'bestvideo+bestaudio' URL` |

---

## System Monitoring

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `asitop` | Apple Silicon 모니터링 (CPU/GPU/Neural Engine) | `sudo asitop`, M1/M2 전용 |
| `bottom` | htop 대체, 그래프/프로세스 TUI | `btm`, 더 직관적인 UI |
| `htop` | top 대체, 인터랙티브 프로세스 모니터 | `htop`, `F9`로 프로세스 종료 |

---

## Window Management & UI

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `borders` | SketchyBar용 윈도우 테두리 강조 | 현재 포커스 윈도우 하이라이트 |
| `sketchybar` | 커스텀 macOS 메뉴바 (플러그인 기반) | `.config/sketchybar/`, 시스템 정보 표시 |
| `skhd` | 키보드 단축키 데몬 (Yabai와 주로 사용) | `.config/skhd/skhdrc`, `cmd+shift+enter` → 터미널 실행 |
| `qmk` | QMK 키보드 펌웨어 빌드/플래시 | `qmk compile -kb planck -km default` |

---

## Fonts (Cask)

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `font-batang` | 바탕체 (한글 세리프 폰트) | 문서 작업용 |
| `font-carrois-gothic` | Carrois Gothic (제목용 Sans-serif) | UI 디자인 |
| `font-meslo-lg-nerd-font` | Meslo Nerd Font (터미널 아이콘 지원) | Powerlevel10k, WezTerm에서 사용 |
| `font-sarasa-gothic` | 사라사 고딕 (한중일 프로그래밍 폰트) | 코딩용, 리가처 지원 |
| `font-sf-pro` | San Francisco Pro (Apple 시스템 폰트) | macOS 네이티브 디자인 |

---

## Desktop Applications (Cask)

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `claude-code` | Claude Code CLI + Desktop 앱 | AI 코딩 어시스턴트, `claude -p` 실행 |
| `devtoys` | 개발자 도구 모음 (JSON 포맷/Base64 등) | 스위스 아미 나이프 앱 |
| `ghostty` | GPU 가속 터미널 에뮬레이터 | `.config/ghostty/config`, 빠른 렌더링 |
| `gureumkim` | macOS 한글 입력기 | 세벌식/모아치기 지원 |
| `hammerspoon` | Lua 기반 macOS 자동화 | `.hammerspoon/init.lua`, 윈도우 관리 스크립트 |
| `keycastr` | 키 입력 시각화 (화면 녹화 시 유용) | 프레젠테이션/튜토리얼 제작 |
| `ngrok` | 로컬 서버 → 공개 URL (터널링) | `ngrok http 3000` → 외부 접속 가능 |
| `orbstack` | Docker Desktop 대체 (더 빠름) | `docker` CLI 호환, Linux VM 지원 |
| `qlmarkdown` | QuickLook Markdown 프리뷰 | Finder에서 스페이스바로 `.md` 미리보기 |
| `qmk-toolbox` | QMK 펌웨어 플래시 GUI | 키보드 펌웨어 업로드 |
| `rectangle` | 윈도우 크기/위치 조절 | `Ctrl+Opt+Enter` 전체화면, `Ctrl+Opt+Left` 왼쪽 절반 |
| `sf-symbols` | Apple SF Symbols 브라우저 | macOS 아이콘 검색/복사 |
| `wkhtmltopdf` | HTML → PDF 변환 (WebKit 기반) | `wkhtmltopdf input.html output.pdf` |
| `youtype` | macOS 입력 도구 (자동 교정?) | - |
| `zed` | 고속 코드 에디터 (Rust 기반) | `.config/zed/settings.json`, 멀티플레이어 편집 |
| `textream` | 텍스트 에디터 | - |
| `claude-usage-tracker` | Claude API 사용량 트래커 | Alfred 워크플로우 모니터링용 |
| `aerospace` | 타일링 윈도우 매니저 (i3 스타일) | `.config/aerospace/aerospace.toml`, `Opt+1~9` 워크스페이스 |
| `jordanbaird-ice` | 메뉴바 아이콘 숨기기 | 메뉴바 정리 도구 |

---

## Go Packages

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `fabric` | AI 기반 CLI 워크플로우 프레임워크 | `fabric --pattern summarize < article.txt` |
| `to_pdf` | Fabric 플러그인, HTML → PDF 변환 | Fabric 워크플로우 내에서 사용 |

---

## Cargo Packages (Rust)

| 패키지 | 설명 | 활용 |
|--------|------|------|
| `agf` | 커스텀 도구 (용도 확인 필요) | 개인 프로젝트? |
| `cargo-generate` | Cargo 프로젝트 템플릿 생성기 | `cargo generate --git template-repo` |
| `create-tauri-app` | Tauri 앱 스캐폴딩 | `cargo create-tauri-app` → 데스크탑 앱 프로젝트 생성 |
| `obsidian-lsp` | Obsidian Vault LSP 서버 | Neovim에서 Obsidian 노트 편집 시 자동 완성 |

---

## 업데이트 가이드

### Brewfile 동기화
```bash
# 현재 설치된 패키지로 Brewfile 업데이트
brew bundle dump --force

# Brewfile에 없는 패키지 확인
brew bundle cleanup --force

# Brewfile로부터 설치
brew bundle install
```

### 패키지 검색
```bash
# 패키지 설명 확인
brew info <package>

# 포뮬러 검색
brew search <keyword>

# 설치된 패키지 목록
brew list --formula  # CLI 도구
brew list --cask     # GUI 앱
```

### 정리
```bash
# 오래된 버전 삭제
brew cleanup

# 캐시 정리
brew cleanup -s

# 진단
brew doctor
```

---

## 주요 의존성 체인

- **Neovim 개발환경**: `neovim` → `lua-language-server`, `jdtls`, `yaml-language-server`, `rust-analyzer`
- **터미널 향상**: `zsh` → `powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fzf`, `zoxide`
- **윈도우 관리**: `aerospace` or (`yabai` + `skhd`) + `hammerspoon` + `rectangle`
- **파일 탐색**: `yazi` → `ueberzugpp` (이미지 프리뷰), `fd`, `ripgrep`, `bat`
- **Git 워크플로우**: `git` → `git-delta`, `lazygit`, `gh`
- **Java 개발**: `openjdk@21` → `jdtls`, `maven`, `gradle`
- **Obsidian 워크플로우**: `obsidian-lsp` (Cargo) + `markdown-oxide` (LSP) + Alfred 스크립트

---

**메모**:
- 일부 패키지(aoe, youtype, textream)는 용도가 명확하지 않으므로 추후 검토 필요
- Cask 앱은 `/Applications/`에 설치됨
- Go/Cargo 패키지는 `$GOPATH/bin`, `~/.cargo/bin`에 설치됨
- 이 문서는 `brew bundle dump` 실행 시 자동 업데이트되지 않으므로 수동 동기화 필요
