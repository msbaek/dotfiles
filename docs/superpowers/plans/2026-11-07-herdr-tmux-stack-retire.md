# herdr 이관 2단계: tmux 기반 Claude 세션 추적 스택 비활성화 계획

**Status**: planned (실행 전) · 작성 2026-11-07
**전제**: herdr 트라이얼 확정 후 tmux를 Claude 세션 실행 환경으로 사용하지 않는다고 결정했을 때 실행한다.
**원칙**: 파일은 삭제하지 않고 **호출 지점만 끊는다**(hook 등록 해제·alias/function 로드 중단·tmux bind 주석). 1개월 미사용 확인 후 삭제 커밋을 별도로 만든다.

## Goal (testable)

- Claude Code tool call 1회당 외부 프로세스 생성 0건(현재 session-tracker node 2회).
- `which cw cj cwq` → 미정의. `tmux list-panes -a -F '#{@cc_state}'` 가 빈 값.
- herdr sidebar(`agent_status` idle/working/blocked/done)와 `prefix+u`(goto)만으로 세션 이동·대기 판별이 가능하다.

## Constraints

- 두 repo, 두 커밋: hook·bin = `~/claude-config`(`herdr-trial` 브랜치), zsh·tmux.conf·cheats = `~/dotfiles`.
- 커밋은 `--no-verify`(pre-commit stash 유실 사고 메모리).
- `herdr-agent-state.sh`(herdr 관리 hook)는 유지.
- `msbaek.cheats`의 cw·cj·cwq·abtop 행 동반 제거(mshelp 메모리).

## 대체 매핑

| 기존(tmux 스택) | herdr 대체 | 비고 |
|---|---|---|
| `cc-attention.sh` → `@cc_state` attention/waiting/running/idle | `agent_status` blocked/done/working/idle(`herdr agent explain`: 화면 prompt_box 규칙 기반) | hook 없이 서버가 터미널 출력으로 판정 |
| `cw` / `cwq` (waiting-first fzf 점프) | sidebar 상태 아이콘 + `prefix+u` goto, `herdr agent list` | 우선순위 정렬은 sidebar 순서로 대체 |
| `cj` (프로젝트 → pane 점프/cd) | `prefix+w` workspace 피커 + `herdr workspace` | `cc-projects.list` 는 workspace 명으로 흡수 |
| `ccj` + `session-tracker.sh/.mjs` (`~/.claude/dashboard/active`) | `herdr agent list --json` | dashboard/active 유일한 reader가 ccj |
| tmux-claude-hatch (prefix Y/u) | herdr goto(prefix+u) + `herdr agent start` | |
| tmux `bind a`(abtop hub) · `set-titles`(aerospace 매핑) | herdr `window_title = "{workspace}: ..."` | abtop popup은 herdr `prefix+a` 로 이미 이관 |
| `~/.tmux/scripts/tmux-dashboard.sh` (prefix D) | herdr sidebar | |

## Tasks

### Task 1 — hook 호출 해제 (claude-config)
- settings.json에서 `cc-attention.sh` 5개(Notification·Stop·SessionStart·SessionEnd·UserPromptSubmit), `session-tracker.sh` 9개(모든 이벤트) 등록 삭제.
- Output: `python3 -c json.load` OK, `grep -c 'cc-attention\|session-tracker' settings.json` = 0.
- Failure: herdr 밖 plain 터미널에서 Claude 실행 시 상태 추적 수단이 전무 — 허용(herdr 전용 결정).

### Task 2 — zsh 함수 로드 중단 (dotfiles)
- `.zsh.after/cw.zsh`, `cj.zsh` 를 `.zsh.after/_retired/` 로 이동(`.zshrc` 글롭 범위 밖). `cc-projects.list` 동반 이동.
- `msbaek.cheats` 에서 `cw`·`cj`·`cwq` 행 삭제(abtop은 herdr popup으로 남으므로 유지).
- Output: 새 셸에서 `type cw` → not found.

### Task 3 — tmux.conf 바인딩 주석 (dotfiles)
- `bind a switch-client -t abtop`, `set-titles*` 2줄, `@plugin tmux-claude-hatch` + `@claude_*` 3줄, `bind D` dashboard 를 주석 처리(헤더에 `# retired 2026-xx herdr`).
- tmux는 Claude 외 용도(SSH 중첩 등)로 남을 수 있으므로 설정 파일 자체는 유지.

### Task 4 — ccj 비활성화 (claude-config)
- `bin/ccj` 실행 권한 제거 또는 `bin/_retired/` 이동. `~/.claude/dashboard/active/` 잔존 json 삭제.

### Task 5 — 검증·기록
- herdr 안에서 Claude 1회 실행 → `herdr agent list` 에 idle/working 전이 확인, hook 프로세스 생성 없음(`ps` 확인).
- journal + memory(`hunk`/`cc-attention` 관련 메모리 2건에 retired 표기).

## 삭제 커밋(1개월 후)
`_retired/` 디렉토리, `hooks/cc-attention.sh`, `hooks/tests/test-cc-attention.sh`, `hooks/session-tracker.*`, `bin/ccj`, `tmux-dashboard.sh`, 그리고 1단계에서 남긴 `langfuse-trace-*.sh`·`~/.crewnotch/`.

## Rollback
각 Task는 독립 커밋. `git revert <sha>` 후 `stow --no-folding -t ~ .`(dotfiles) 또는 Claude 재시작(claude-config hook).
