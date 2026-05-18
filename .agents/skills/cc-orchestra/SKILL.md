---
name: cc-orchestra
description: >
  Multi-project tmux orchestration for Codex. Sets up tmux session/window
  with CC instances per project, then dispatches prompts.
  Use when (a) the user says "cc-orchestra" or asks to orchestrate multiple
  projects, OR (b) the user mentions another project name as a dispatch target
  (e.g. "pacman에서 X 해줘", "thomas와 bo에 Y 적용", "<proj>에서 ..."),
  OR (c) the assistant determines that work belongs to a sibling project
  (file paths under another repo, plan document assigns the task there, build
  /test ownership lies elsewhere) while running as the main pane of an active
  task. Skip when the user says "여기서 / 이 파일 / 현재 프로젝트" or the work
  is clearly within the current pane's project.
---

# cc-orchestra

enc-mask 같은 multi-project workspace에서 Codex 인스턴스를 tmux로 구성하고
개별 프로젝트 pane에 prompt를 dispatch하는 skill.

## Commands (via zsh wrappers in functions.zsh)

| Command | Description |
|---------|-------------|
| `ccup <task> <main> [sub...]` | session 모드로 환경 구성 (default) |
| `ccup --window <task> <main> [sub...]` | window 모드로 환경 구성 |
| `ccsend <proj> "prompt"` | named project pane에 dispatch |
| `ccadd <task> <proj> <path>` | 실행 중 환경에 pane 추가 |
| `ccrm <task> <proj>` | 실행 중 pane 제거 |
| `cclist` | 활성 task + pane 목록 |
| `ccdown <task>` | 환경 종료 |

## Dispatch 방법

사용자가 특정 프로젝트에 작업을 지시하면 해당 프로젝트 pane에 `ccsend`로 dispatch:

```bash
# pacman 프로젝트에 작업 지시
ccsend pacman "implement the ISMS-184 delivery ID bulk SSN encryption"
```

## Dispatch trigger rules (CC)

메인 pane의 CC는 사용자 발화에서 다른 프로젝트 이름이 명시되면 자동으로 그 pane에 dispatch:

- "pacman에서 X 해줘" → pacman pane에 dispatch
- "thomas와 bo 모두에 Y 적용" → thomas, bo pane에 순차 dispatch
- "여기서 / 이 파일 / 현재 프로젝트" → 자기 자신이 처리

## How to dispatch (CC commands)

CC의 Bash tool은 zsh function `ccsend`를 보지 못한다. wrapper script를 1줄로 호출:

```bash
~/.Codex/skills/cc-orchestra/scripts/cc-dispatch.sh <proj> "<프롬프트>"
```

wrapper 내부에서 `active-task.sh`로 현재 tmux session의 task를 자동 탐지 후 `send.sh`로 위임. tmux 밖이거나 매칭 0/2+개면 비0 종료 → 사용자에게 task명 명시 요청.

**dispatch 전 확인 정책 — trigger에 따라 다름:**

| Trigger | 확인 여부 | 조건 |
|---|---|---|
| A — 사용자 발화에 프로젝트명 명시 | **즉시 dispatch** | "pacman에서 X 해줘" 같이 프로젝트가 발화에 포함 |
| B — CC 자체 파일·계획문서 추론 | **확인 후 dispatch** | 사용자가 프로젝트를 언급하지 않아 CC가 추론한 경우 |

Trigger A일 때는 `cc-dispatch.sh` 즉시 실행 후 결과만 안내:
```
→ pacman pane에 전송했습니다.
  로그: tail -f /tmp/cc-<task>-pacman.log
```

Trigger B일 때는 메시지 미리보기 + 확인 요청:
```
다음을 <proj> pane에 dispatch하려고 합니다. 진행할까요?

<메시지 본문 미리보기>
```

## How to add/remove panes (CC commands)

새 프로젝트 pane 동적 추가:

```bash
~/.Codex/skills/cc-orchestra/scripts/cc-add.sh <proj> <path>
```

추가 직후 dispatch는 Codex 부팅 대기(~5초) 필요. 즉시 보내면 입력이 씹힐 수 있음.

pane 제거:

```bash
~/.Codex/skills/cc-orchestra/scripts/cc-remove.sh <proj>
```

활성 task 목록은 `~/.Codex/skills/cc-orchestra/scripts/list.sh` (인자 없음, task 자동 탐지 불필요).

## 주의사항

- 각 pane의 CC 인스턴스는 해당 프로젝트 cwd에서 시작 → AGENTS.md/.Codex/ 자동 로딩
- pane ID는 `~/.cc-orchestra/<task>.env`에 저장됨
- 세션 재접속 후에도 env 파일 유효 (tmux server 살아있는 동안)
