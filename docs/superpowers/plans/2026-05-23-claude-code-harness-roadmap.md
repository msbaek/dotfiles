# Claude Code Harness Roadmap

> 작성: 2026-05-23 | 상태: active

## 목표 (testable)

Claude Code 사용 패턴의 friction을 자동 수집·분석·개선하는 closed-loop harness 구축.
리포트 데이터: 2,372 messages / 333 sessions / 20일 / 21 user-rejected / 72 command failed / ExitPlanMode 중단 5+회.

**성공 기준**: 4주 후 friction 이벤트(user-rejected + command failed)가 현재 대비 20% 이상 감소.

## 한 줄 진단

skills/agents/hooks 자산은 풍부하지만 **실패·마찰 신호가 telemetry/에 402 파일로만 쌓이고 학습 루프로 환원되지 않는다**.

---

## 인프라 레이어 (Hook 신뢰성)

### [x] Action 7: State File GC — SessionEnd Hook

**커밋**: `68dbd48` (2026-05-23)

- `~/.claude/hooks/session-end-cleanup.sh` 신규 생성
- SessionEnd 시 `/tmp/claude-model-decision-{sessionId}.json` + `model-pending-*.json` 삭제
- `proficiency/pending` 7일 초과 파일 pruning
- settings.json SessionEnd 배열에 등록 (session-tracker → proficiency-enqueue → **cleanup**)
- 부산물: settings.json + settings.local.json 하드코딩 절대경로 → `$HOME` 정규화

### [x] Action 6: Hook Timeout Wrapper + Error Dead Letter Queue

**커밋**: `f2636f9` (2026-05-23)

- `~/.claude/bin/run-hook-with-timeout.sh` 신규 작성 (10s timeout + DLQ)
- stdin을 temp file로 버퍼링 후 재전달 — node `readFileSync(0)` 호환
- 실패/timeout 시 `~/.claude/state/hook-errors/{TS}-{LABEL}.json` 기록
- settings.json 내 `session-tracker.sh` 9개 호출 전부 wrapper 적용
- `hook-errors/` 디렉토리는 `.claude/state/` gitignore 규칙에 자동 제외

### [x] Action 8: Hook 검증 스크립트

**커밋**: `11202b2`, `69817c7` (2026-05-23)

- `~/.claude/bin/validate-hooks.sh` — Python-in-bash 3-rule validator
- Rule 1: 파일 존재 (토큰 루프 + sh -c 내부 regex 이중 커버)
- Rule 2: timeout 누락 경고 (run-hook-with-timeout.sh wrapper 면제)
- Rule 3: 하드코딩 절대경로 → `$HOME` 치환 권장
- Exit 0/1/2 분리 (warnings-only / errors / self-failure)
- skills-log.sh hook에 `"timeout": 5` 추가

---

## 관찰 레이어 (데이터 수집·분석)

### [x] Action 1: Friction Telemetry 분석 파이프라인

**커밋**: `6614594` (2026-05-23)

- `~/.claude/bin/friction-audit.py` 작성 — 402개 telemetry 파일 파싱
- `tengu_tool_use_error` by toolName, user-rejected, MCP/API/plugin 분리 집계
- `--days N`, `--today`, `--count-only` (statusline 대비), `--json` 옵션
- 결과: top-1 friction = MCP connection failed 337회 > plugin_load_failed 70회 > api_retry 189회

**검증**: 1주 후 top-1 friction tool fix → 다음 주 빈도 감소 확인

### [x] Action 2: Pre-flight Hook on ExitPlanMode

**커밋**: `9569b3d` (2026-05-23)

- `~/.claude/hooks/preflight-exitplan.py` 신규 작성
- `subagent_type:` 값 → known agents(`~/.claude/agents/*.md`) 대조
- `/slash-name` → known skills(`~/.claude/skills/*/` + `~/.claude/commands/`) 대조
- prefix:skill 네임스페이스 처리 (obsidian:x → prefix `obsidian` 체크)
- 결손 시 stderr 경고 + `additionalContext`로 Claude에 전달, 항상 allow
- settings.json `PreToolUse[ExitPlanMode]` 등록, timeout wrapper 적용

**검증**: 1주 후 ExitPlanMode 중단율 25% → 10% 이하

### [x] Action 3: Statusline friction signal 노출

**커밋**: `f9d6f56` (2026-05-23)

- `get_friction_count()` 함수 추가: `/tmp/friction-today-cache.txt` 5분 캐시
- `friction-audit.py --today --count-only` 호출 → `3✗ 2⊘` 형태 표시
- 0✗ 0⊘ 이면 표시 생략 (노이즈 제거)
- Combine 블록 배열 기반으로 리팩토링

---

## Strategic

### [ ] Action 4: Skill Golden Test Harness (langfuse 연동)

**우선순위**: 🟣 Strategic (별도 plan 필요)

- `skills-tests/` 디렉토리 + 각 skill 마다 3-5개 golden input/output
- 주간 sub-agent 격리 실행 + pass rate 추적
- langfuse OTLP exporter로 trace 수집
- 첫 대상: `/commit` skill

### [ ] Action 5: Self-reflection MCP Server

**우선순위**: 🟣 Strategic (별도 plan 필요)

- Python FastAPI 기반 local MCP server
- endpoint: `recent_friction(days)` / `skill_usage_stats(skill)` / `suggest_skill_for(intent)` / `session_recap(session_id)`
- telemetry/ + history.jsonl + journals/ 통합 조회

---

## 의도적으로 무시하는 추천

| 리포트 추천                    | 무시 이유                                                   |
| ------------------------------ | ----------------------------------------------------------- |
| "Custom Skills 추가" 일반 권고 | 이미 50+ skill. 신규보다 기존 friction 측정·개선이 ROI 높음 |
| "Hooks 사용 시작" 일반 권고    | 이미 9개 lifecycle 모두 등록됨                              |
| CLAUDE.md 추천 4개             | 현재 CLAUDE.md가 모두 커버함                                |

---

## Resume Point

**완료**: Actions 1, 2, 3, 6, 7, 8 — 인프라 + 관찰 레이어 모두 완성.

**다음 시작**: Action 4 (Skill Golden Test Harness) 또는 Action 5 (Self-reflection MCP Server) — 별도 brainstorming 세션 필요.
- Action 4: `/commit` skill golden input/output + langfuse OTLP trace
- Action 5: Python FastAPI local MCP server + telemetry/history.jsonl/journals 통합
