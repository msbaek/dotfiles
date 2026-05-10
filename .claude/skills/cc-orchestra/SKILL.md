---
name: cc-orchestra
description: >
  Multi-project tmux orchestration for Claude Code.
  Use when the user says "cc-orchestra" or asks to orchestrate multiple projects.
  Sets up tmux session/window with CC instances per project, then dispatches prompts.
---

# cc-orchestra

enc-mask 같은 multi-project workspace에서 Claude Code 인스턴스를 tmux로 구성하고
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

## 주의사항

- 각 pane의 CC 인스턴스는 해당 프로젝트 cwd에서 시작 → CLAUDE.md/.claude/ 자동 로딩
- pane ID는 `~/.cc-orchestra/<task>.env`에 저장됨
- 세션 재접속 후에도 env 파일 유효 (tmux server 살아있는 동안)
