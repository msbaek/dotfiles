---
name: vis-backlink-status
description: Use when user asks about background vis-backlink (reverse Related Notes update) progress. Reads ~/.claude/state/vis-backlink/ and reports active/recent/failed jobs with progress bars. Trigger on "vis-backlink 상태", "역방향 진행", "backlink 어디까지", "/vis-backlink-status".
---

# vis-backlink-status

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 B 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`vis-backlink-status-reader`** 사용 (전용 sub-agent).
(model="haiku", run_in_background=false, args=skill 호출 인자, 옵션=`--clear-failed`, `--json`, `--follow`)

main context에서 직접 실행 금지.

background vis-backlink job (새 Obsidian 문서 생성 시 역방향 Related Notes 업데이트) 의 진행 상태를 보고한다. LLM 호출 없음, vis daemon 비의존.

## When to use

- 슬래시 커맨드: `/vis-backlink-status [options]`
- 자연어: "vis-backlink 상태", "역방향 진행 어디까지", "백링크 작업 현황", "backlink job 확인"

## Options

| Option | 동작 |
|---|---|
| (없음) | 기본 요약 (활성 + 최근 5 history + 실패) |
| `--clear-failed` | `active/` 의 `failed`/`partial_failure`/`crashed` job 을 `history/` 로 이동 |
| `--json` | 파싱된 전체 상태를 JSON 덤프 |
| `--follow` | v2 (미구현, 안내만) |

## Procedure

0. Bash: `[ -f ~/.claude/state/vis-backlink/.disabled ] && echo OFF || echo ON` → 활성화 상태.
1. Bash: `ls ~/.claude/state/vis-backlink/active/*.json 2>/dev/null` → 활성 목록.
2. Bash: `ls -t ~/.claude/state/vis-backlink/history/*.json 2>/dev/null | head -5` → 최근 history.
3. 각 JSON 파일을 Read.
4. 집계 후 아래 포맷으로 출력:

```
=== vis-backlink 상태 (YYYY-MM-DD HH:MM:SS) ===
활성화: ON   (또는: OFF — backward 비활성화, /vis-backlink-toggle on 으로 재활성화)

활성 (N):
  [20260415-104523-new-doc] phase=processing
    source: 001-INBOX/new-doc.md
    progress: [####----] 2/3 (current: 003-RESOURCES/baz.md)
    elapsed: 34s
    subagent: vis-backlink-a1b2

최근 완료 (5):
  [20260415-093011-foo] done=3/3 duration=78s
  [20260415-083512-bar] done=2/3 duration=52s partial (1 skipped)
  ...

실패 (M):
  [20260414-221045-crash] phase=crashed
    source: 001-INBOX/whatever.md
    last step: llm_description_generation (target=baz.md)
    힌트: /vis-backlink-status --clear-failed 로 정리
```

5. 실패 존재 시 마지막에 `--clear-failed` 힌트 표시.

## --clear-failed 서브프로시저

```
for each active/*.json where phase in {failed, partial_failure, crashed}:
  mv active/<id>.json history/<id>.json
report: "cleared N failed jobs → history/"
```

파일 권한 실패 시 skip 하고 사유 보고.

## --json

모든 active + 최근 30 history 를 단일 JSON 으로 출력:

```json
{
  "now": "<ISO8601>",
  "active": [<job-json>, ...],
  "history_recent": [<job-json>, ...]
}
```

## 의존성

- Tools: Read, Bash (ls, mv, jq 선택적)
- 파일: `~/.claude/state/vis-backlink/active/*.json`, `~/.claude/state/vis-backlink/history/*.json`
- **LLM 호출 없음, vis daemon 비의존.**

## 에러 처리

- state_dir 부재 → "아직 vis-backlink job 이 실행된 적이 없습니다" 안내.
- JSON 파싱 실패 → 해당 파일은 `[corrupted: <path>]` 로 표시, 나머지는 계속.
- 동시 쓰기로 인한 partial read → 재시도 1 회 후 실패 시 위와 동일하게 표시.

## References

- Spec: `~/git/vault-intelligence/docs/superpowers/specs/2026-04-15-vis-backlink-reverse-update-design.md` (§C11)
- Hook: `~/.claude/CLAUDE.md` `<when-creating-obsidian-document>` backward 블록
- Toggle: `/vis-backlink-toggle` (on/off 사용자 토글)
