# SP1 — hunk 테마 + git pager 통합 (dotfiles)

- **Date**: 2026-07-08
- **Status**: implemented (2026-07-08) — 전 acceptance criteria 통과. `.gitconfig.user` 커밋만 dotfiles-private 에서 사용자 몫으로 대기
- **Repo scope**: `dotfiles` (+ `dotfiles-private` 소량 정리)
- **후속**: SP2 — Claude Code agent-review 자동화 (별도 spec, `claude-config`)

## Goal (testable)

hunk을 이 환경의 기본 diff 뷰어로 통합한다. 구체적으로:

1. `hunk diff`(및 `hd`)가 **Atom One Light 커스텀 테마**로 열려 ghostty 화면과 시각적으로 일치한다.
2. `git diff` / `git show`가 **전역적으로 hunk pager**로 열린다.
3. delta로 **즉시·무손실 복구**할 수 있는 3중 롤백 경로가 존재한다.

## Context (현재 상태, 조사 완료)

- hunk 0.17.0 설치됨 (`/opt/homebrew/bin/hunk`, brew). 설정: `~/.config/hunk/config.toml` (전역) 또는 `.hunk/config.toml` (레포별). 런타임 상태 `~/.config/hunk/state.json`은 hunk가 관리(추적 안 함).
- ghostty theme = **Atom One Light** (`~/dotfiles/.config/ghostty/config`), `palette 0=#dbe9f6`, `background-opacity=1`.
- `hd = hunk diff --theme github-light-high-contrast` (`~/dotfiles/.zsh.after/msbaek.zsh:299`).
- **git pager 현황**: 실제 pager 결정권자는 tracked `.gitconfig`가 아니라 `~/.gitconfig.user`(→ `dotfiles-private/.gitconfig.user`, dotfiles에선 gitignore). `[include]`(`.gitconfig:134`)가 `[core] pager=delta`(`.gitconfig:121`) **뒤에** 로드되어 `.gitconfig.user`의 `pager=delta`가 이긴다(shadow).
- hunk 커스텀 테마 지원 확인: `[custom_theme]`가 built-in을 `base`로 상속하고 색만 override. 모든 색은 `#rrggbb`.

## 확정된 결정

| # | 결정 | 근거 |
|---|---|---|
| D1 | 테마 = Atom One Light 커스텀 (`base = github-light`) | ghostty와 일치. hunk엔 atom-one-light built-in 없음 |
| D2 | 전역 pager = `hunk pager`, delta 롤백 경로 보존 | 사용자 승인(hunk agree). reversibility 우선 |
| D3 | `.gitconfig.user`의 중복 pager/difffilter/`[delta]` 블록 제거 | 사용자 승인(hunk agree). shadow 제거로 tracked `.gitconfig`를 유일 권위로 |

## 설계

### A. 테마 — `~/dotfiles/.config/hunk/config.toml` (신규, stow)

```toml
theme = "custom"
mode  = "auto"        # auto/split/stack
vcs   = "git"

[custom_theme]
base  = "github-light"   # 라이트 베이스 상속, 아래 색만 override
label = "Atom One Light"
# Atom One Light 팔레트 (구현 시 정확한 override 키로 매핑):
#   bg #fafafa · fg #383a42 · comment/gray #a0a1a7
#   blue #4078f2 · green(addition) #50a14f · red(deletion) #e45649
#   yellow #c18401 · purple #a626a4 · cyan #0184bc
```

- 배경은 **불투명 `#fafafa` 명시** (사용자 결정: transparent 불필요).
- **전역 config 하나만** 유지 — per-repo `.hunk/config.toml`은 쓰지 않는다 (사용자 결정).
- 기본 테마가 config에 생기므로 `hd`의 `--theme` 인자는 제거(중복 제거).
- stow: `~/.config/hunk/` 실디렉토리에 `config.toml`만 fold, `state.json`과 공존.

### B. 전역 hunk pager + 안전 롤백

- **`dotfiles-private/.gitconfig.user`** (편집): 중복 `[core] pager` / `[interactive] diffFilter` / `[delta]` 블록 제거. `[user]` 등 identity만 남긴다. (de-shadow)
- **`~/dotfiles/.gitconfig`** (편집):
  - `[core] pager = hunk pager` (기존 `delta` 대체). `# pager = delta` 주석으로 원값 보존.
  - `[interactive] diffFilter = delta --color-only` **유지** (hunk엔 difffilter 없음 → `git add -p`용으로 delta 존치).
  - `[delta]` 섹션 **유지** (롤백 즉시 동작).
  - `[alias]`에 일회성 delta escape 추가: `ddiff = -c core.pager=delta diff`, `dshow = -c core.pager=delta show`.
- **롤백 3중 안전망**:
  1. `gpager hunk|delta` — 런타임 토글 zsh 함수 (`git config -f ~/.gitconfig core.pager ...`), 파일 손편집 없이 즉시 전환.
  2. `git ddiff` / `git dshow` — 전역 변경 없이 한 번만 delta.
  3. delta 바이너리 + `[delta]` 설정 존치 → 언제든 무손실 복귀.

### C. alias / cheats — `~/dotfiles/.zsh.after/`

- `hd = hunk diff --watch` — **watch 기본**(사용자 결정). config에 기본 테마가 생기므로 `--theme` 인자 제거. 별도 `hdw` 불필요(통합).
  - 역할 분담: 일회성 diff = `git diff`(hunk pager), 지속 라이브 리뷰 = `hd`(watch).
- `gpager` 함수 추가.
- `hd`(watch)·`gpager`를 `msbaek.cheats`에 반영 (mshelp 동기화 — 사용자 명시 요청).

## File Inventory

| 파일 | repo | 변경 |
|---|---|---|
| `.config/hunk/config.toml` | dotfiles | 신규 (테마 D1) |
| `.gitconfig` | dotfiles | pager 교체 + delta 주석 + ddiff/dshow alias |
| `.gitconfig.user` | dotfiles-private | 중복 pager/difffilter/`[delta]` 블록 제거 (D3) |
| `.zsh.after/msbaek.zsh` | dotfiles | `hd`를 `--watch`로 변경 + `gpager` 함수 추가 |
| `.zsh.after/msbaek.cheats` | dotfiles | 신규 alias/함수 문서화 |

## Acceptance Criteria (완료의 정의)

1. `hunk diff`가 `--theme` 없이 Atom One Light 커스텀 테마로 열리고 ghostty와 시각적으로 유사하다.
2. `git config core.pager`의 **effective 값**이 `hunk pager`이고, `git diff`/`git show`가 hunk로 열린다.
3. `gpager delta` → 즉시 delta로, `gpager hunk` → 즉시 hunk로 복귀. `git ddiff`는 전역값을 안 바꾸고 delta로 1회.
4. `.gitconfig.user`가 더 이상 pager/difffilter를 선언하지 않는다(`git config --show-origin`로 확인).
5. `git add -p`가 여전히 delta difffilter로 동작(hunk 전환과 무관).
6. `hd`(watch) 동작 + `gpager`가 `mshelp`에 노출.
7. stow 후 `~/.config/hunk/config.toml` 심링크 + `state.json` 공존.

## Reversibility

- 전 변경 git 추적(dotfiles/dotfiles-private) → revert 가능.
- pager는 런타임 토글(`gpager`)로 파일 편집 없이 즉시 원복.
- delta 바이너리·설정 삭제하지 않음.

## Out of Scope (→ SP2, claude-config)

- 편집 마무리 체크포인트 hook (Stop / UserPromptSubmit).
- `~/.claude/skills/hunk-review/` 영속 설치.
- Claude ↔ 사용자 hunk 피드백 루프 자동화.

## Open Items (구현/planning에서 해소)

- `[custom_theme]` 정확한 override 키 스키마 (hunk 바이너리에서 추출 or 인앱 `t`로 반복 조정).
- `gpager`가 `git config -f ~/.gitconfig`에 쓸 때 `.gitconfig.user` de-shadow가 선행되어야 effective 반영됨(순서 의존) — 구현 시 검증.
