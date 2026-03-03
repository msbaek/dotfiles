---
name: obsidian-jobs
description: |
  Alfred 핫키로 실행된 obsidian-summarize 작업의 상태를 확인.
  "작업 상태", "job status", "진행 상황", "obsidian jobs" 등의 요청 시 자동 적용.
user_invocable: true
---

# obsidian-jobs - Obsidian Summarize 작업 상태 확인

## 개요

Alfred 핫키로 실행된 `obsidian-summarize.sh` 작업들의 진행 상태를 확인하는 skill.

## 실행 방법

1. **활성 tmux 세션 확인**: `tmux list-sessions 2>/dev/null | grep obsidian`
2. **로그 파일 확인**: `tail -50 /tmp/obsidian-summarize.log`

## 출력 형식

### 활성 세션이 있을 때

로그에서 마지막 START~END 블록을 파싱하여 다음 정보를 표시:

| 항목 | 내용 |
|------|------|
| URL | 처리 중인 URL |
| 타입 | youtube-en / youtube-kr / article |
| 시작 시각 | HH:MM:SS |
| 상태 | 실행 중 / 대기 중 (lock 대기) |

### 활성 세션이 없을 때

오늘 로그에서 완료/실패 기록을 요약하여 표시:

| 시각 | 타입 | URL | 결과 |
|------|------|-----|------|
| HH:MM | article | medium.com/... | ✅ / ❌ |

## 재실행 안내

실패한 작업이 있으면 재실행 명령어를 제안:

```bash
tmux new-session -d -s "obsidian-retry-$(date +%s)" \
  "$HOME/bin/obsidian-summarize.sh --execute <type> '<url>'"
```

사용자가 재실행을 요청하면 위 명령어를 실행합니다.

## 참고 파일

- 스크립트: `~/bin/obsidian-summarize.sh`
- 공유 로그: `/tmp/obsidian-summarize.log`
- Lock 파일: `/tmp/obsidian-summarize.lock`
- 에러 로그: `$VAULT_ROOT/001-INBOX/error-list.md`
