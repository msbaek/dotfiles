# Daily Work Logger 배치 실행 계획

## 목표
Tmux Orchestrator를 이용하여 **2025-06-20 ~ 2026-01-15** 기간의 daily log를 병렬 처리로 생성

## 핵심 요구사항
1. 날짜 범위 내 **모든 날짜** 대상 (약 210일)
2. Daily Note가 없어도 **작업 내역이 있으면 새로 생성**
3. 작업 내역이 없으면 Daily Note 생성하지 않음

---

## 구현 계획

### Phase 1: 템플릿 생성

**경로**: `/Users/msbaek/git/lib/Tmux-Orchestrator/templates/daily-logger/`

#### 1.1 config.yaml
```yaml
task_name: daily-logger
description: "일괄 Daily Work Logger 실행"

date_range:
  start: "2025-06-20"
  end: "2026-01-15"

processing:
  default_agent_count: 4
  dates_per_agent: 55

paths:
  vault_root: "/Users/msbaek/DocumentsLocal/msbaek_vault"
  dailies: "/Users/msbaek/DocumentsLocal/msbaek_vault/notes/dailies"
```

#### 1.2 agent_template.py
- 각 에이전트에 날짜 목록 전달
- 순차적으로 `/daily-work-logger {date}` 스킬 실행
- 진행 상황 보고 및 완료 신호 출력

### Phase 2: orchestrate.py 수정

**파일**: `/Users/msbaek/git/lib/Tmux-Orchestrator/orchestrate.py`

추가할 기능:
1. `daily-logger` 태스크 타입 추가
2. 날짜 목록 생성 메서드 (`generate_date_range`)
3. 날짜 분배 메서드 (`split_dates_to_agents`)

### Phase 3: daily-work-logger 스킬 수정 (선택적)

**파일**: `/Users/msbaek/.claude/skills/daily-work-logger/SKILL.md`

Phase 3에 조건 추가:
- 3개 서브에이전트 결과가 모두 "없음"인 경우 → Daily Note 생성 안 함
- 하나라도 작업 내역이 있으면 → Daily Note 생성/업데이트

---

## 에이전트 분배 전략

| Agent | 날짜 범위 | 개수 |
|-------|-----------|------|
| Agent 1 | 2025-06-20 ~ 2025-08-10 | ~53일 |
| Agent 2 | 2025-08-11 ~ 2025-10-02 | ~53일 |
| Agent 3 | 2025-10-03 ~ 2025-11-23 | ~52일 |
| Agent 4 | 2025-11-24 ~ 2026-01-15 | ~52일 |

---

## 실행 명령어

```bash
cd /Users/msbaek/git/lib/Tmux-Orchestrator
python3 orchestrate.py daily-logger --date-range 2025-06-20:2026-01-15 --keep-session
```

---

## 수정 대상 파일

1. **생성**: `templates/daily-logger/config.yaml`
2. **생성**: `templates/daily-logger/agent_template.py`
3. **수정**: `orchestrate.py` - daily-logger 태스크 타입 추가
4. **수정** (선택): `~/.claude/skills/daily-work-logger/SKILL.md` - 빈 결과 처리 로직

---

## 검증 방법

1. **테스트 실행**: 3일치만 먼저 실행하여 동작 확인
   ```bash
   python3 orchestrate.py daily-logger --date-range 2026-01-10:2026-01-12 --keep-session
   ```

2. **Daily Note 확인**: 생성된 파일 내용 검토
   ```bash
   ls -la ~/DocumentsLocal/msbaek_vault/notes/dailies/2026-01-1*.md
   ```

3. **전체 실행**: 테스트 성공 후 전체 범위 실행

---

## 사용자 결정 사항

1. **기존 작업 내역 처리**: 추가 방식
   - 기존 내용 유지하고 새 내용을 아래에 추가
   - daily-work-logger 스킬의 Phase 3 수정 필요

2. **에이전트 수**: 4개 (기본값)

---

## Uncertainty Map

**확인 필요**:
- daily-work-logger 스킬이 작업 내역 없을 때 빈 Daily Note를 생성하는지 여부
- 4개 에이전트 동시 실행 시 API rate limit 문제 여부
