# Skills Catalog + Audit + Curate 시스템 설계

**작성일**: 2026-04-17
**대상**: `~/.claude/` 범위의 skill 관리 인프라
**상태**: 설계 승인 완료, 구현 계획 대기

## Goal

150+ 설치된 스킬을 (A) 빠르게 훑고, (C) 실제 사용량 파악하고, (D) 중복/노후 정리 가능하게 만든다.

## Constraints

- hook 최소화 (`settings.json`에 1개 이하 추가)
- plugin 스킬 파일 직접 수정 금지 (override는 `~/.claude/CLAUDE.md` overlay 또는 별도 메모 파일)
- vault/git 외부 의존 없음
- `~/.claude/` 범위 내 완결 (타 프로젝트 영향 없음)
- 외부 Python 패키지 없음 (stdlib 전용)

## Failure Conditions

- 카탈로그가 실제 스킬 상태와 drift → 신뢰 상실
- 로그 무한 증가 → 디스크 부담
- 수동 업데이트 강요 → 유지 안 됨
- Hook 오류로 기존 Skill tool 실행에 지장

## Success Criteria

- 한 명령으로 전체 카탈로그 조회 2초 이내
- 30일 usage 통계 제공 (top/unused/overlap)
- 중복 의심 pair 리스트 출력 (similarity ≥ 0.7)
- Phase별 rollback 가능 (hook 제거 + 파일 삭제)

## Approach

**Hybrid**: auto-generated 카탈로그 + 경량 usage 로깅 + 주기적 수동 curation.

대안 비교:
- Static catalog only: audit 불가, drift 위험
- Full telemetry: hook 복잡, overkill
- **Hybrid (선택)**: 세 문제 모두 커버, control 유지

## Architecture

### 컴포넌트 (5개)

| # | 이름 | 책임 | 위치 |
|---|------|------|------|
| 1 | Scanner | SKILL.md frontmatter 파싱 → JSON | `~/.claude/bin/skills-scan.py` |
| 2 | Catalog Generator | JSON → markdown 인덱스 | Scanner에 통합 |
| 3 | Usage Logger | Skill tool 호출 → JSONL append | `~/.claude/bin/skills-log.sh` + hook |
| 4 | Audit Command | catalog + log → 리포트 | `~/.claude/bin/skills-audit.py` |
| 5 | Curate Command | audit 결과 → 수동 정리 가이드 | `~/.claude/bin/skills-curate.py` |

### 데이터 흐름

```
SKILL.md (150+)
    ↓ Scanner (수동/주기)
skills-index.json  ──→  SKILLS-INDEX.md  (A: discoverability)

Skill tool call
    ↓ PostToolUse hook
skills-usage.jsonl  ──→  /skills-audit  (C: audit)

catalog + log
    ↓ similarity/keyword
overlap pair list  ──→  /skills-curate  (D: curation)
```

### 파일 레이아웃

```
~/.claude/
├── bin/
│   ├── skills-scan.py
│   ├── skills-log.sh
│   ├── skills-audit.py
│   └── skills-curate.py
├── logs/
│   └── skills-usage.jsonl      # append-only, 월별 rotation
├── commands/
│   ├── skills-catalog.md       # /skills-catalog
│   ├── skills-audit.md         # /skills-audit
│   └── skills-curate.md        # /skills-curate
├── SKILLS-INDEX.md             # auto-gen 카탈로그
├── SKILLS-DECISIONS.md         # curate 기록
└── settings.json               # PostToolUse hook 1개 추가
```

### 경계 원칙

- Scanner/Catalog: **read-only** (SKILL.md 수정 금지)
- Logger: **append-only**
- Audit/Curate: **리포트만**, 자동 삭제 없음
- 실제 파일 변경은 user 수동 실행 (curate가 명령 출력만)

## Data Schemas

### 1. `skills-index.json`

```json
{
  "generated_at": "2026-04-17T10:30:00Z",
  "total": 158,
  "sources": {"user": 57, "plugin": 101},
  "skills": [
    {
      "id": "user/find-skills",
      "name": "find-skills",
      "source": "user",
      "plugin": null,
      "path": "~/.claude/skills/find-skills/SKILL.md",
      "description": "Helps users discover...",
      "triggers": ["how do I do X"],
      "category": "meta",
      "mtime": "2026-04-09T09:54:00Z",
      "parse_error": false
    }
  ]
}
```

**카테고리 추론**: prefix (`obsidian-`, `databricks-`, `tdd-`) + description 키워드. 불명확하면 `uncategorized`.

### 2. `skills-usage.jsonl` (append-only)

```jsonl
{"ts":"2026-04-17T10:15:03Z","skill":"superpowers:brainstorming","project":"~/dotfiles","trigger":"user"}
```

**필드**:
- `ts`: ISO 8601 UTC
- `skill`: 플러그인명:스킬명 형식
- `project`: cwd
- `trigger`: `user` (slash) / `auto` (description 매칭)

**Rotation**: 월말 `skills-usage-YYYY-MM.jsonl.gz` 압축. 최근 3개월만 활성.

### 3. Audit 리포트 (JSON)

```json
{
  "period_days": 30,
  "total_calls": 247,
  "top": [{"skill":"superpowers:brainstorming","calls":42,"last":"2026-04-17"}],
  "unused": [{"skill":"brunch-writer","last":"2026-02-15"}],
  "overlap": [{"pair":["find-session","agf"],"similarity":0.78,"shared_keywords":["session","search"]}],
  "stale": [{"skill":"obsidian:tagging-example","mtime":"2025-10-01","calls":0}]
}
```

### 4. `SKILLS-DECISIONS.md`

```markdown
# Skill Curation Log

## 2026-04-17
- [keep] brunch-writer — 연 2회 사용, 유지
- [distinct] find-session ↔ agf — agf=keyword, find-session=semantic
- [archive] old-helper — 6개월 미사용
```

## Interfaces

### CLI

```bash
skills-scan                          # SKILLS-INDEX.md 재생성
skills-scan --json                   # stdout JSON
skills-scan --diff                   # 이전 대비 added/removed

skills-audit --days 30               # 기본 리포트
skills-audit --json                  # curate 입력용
skills-audit --unused-only
skills-audit --overlap-threshold 0.8

skills-curate                        # 대화형
skills-curate --resume               # 중단 재개
skills-curate --batch <json>         # 비대화형 (테스트용)
```

### Slash Commands

```
/skills-catalog         # SKILLS-INDEX.md 재생성 + 미리보기
/skills-audit           # 최근 30일 리포트
/skills-audit 60        # 60일
/skills-audit --unused  # unused만
/skills-curate          # 대화형 정리
/skills-curate --resume
```

### PostToolUse Hook

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/bin/skills-log.sh"
          }
        ]
      }
    ]
  }
}
```

Claude Code hook은 stdin으로 JSON payload 수신 (`tool_input`, `tool_response`, `cwd` 등 포함). `skills-log.sh`는 stdin을 `jq`로 파싱.

`skills-log.sh` 요구사항:
- 10ms 이내 실행
- 실패해도 tool 방해 없음 (항상 exit 0)
- JSON 파싱 실패 시 raw string 기록
- 정확한 hook payload 필드명은 Phase 2 구현 시 공식 docs 재확인

## Error Handling

| 컴포넌트 | 시나리오 | 동작 |
|----------|----------|------|
| Scanner | frontmatter 파싱 실패 | `parse_error: true` 플래그, 전체 중단 안 함 |
| Scanner | 권한 없음 | stderr 경고 + skip, exit 0 |
| Hook | disk full / 권한 오류 | silent fail, tool 실행 방해 금지 |
| Hook | JSON 파싱 실패 | raw string 기록 |
| Audit | 로그 없음 | "7일 이상 수집 필요" 메시지 |
| Audit | 인덱스 없음 | 자동 scanner 호출 후 재시도 |
| Curate | 결정 로그 쓰기 실패 | stderr 에러 + stdout 결정 출력 |

## Testing

**Scanner**:
- Fixture SKILL.md 세트 (frontmatter 유/무, malformed, 심링크) → 예상 JSON 비교
- Idempotent 확인

**Logger hook**:
- Mock tool call → JSONL 1줄 append
- Malformed JSON 입력 → crash 없음
- 실행 시간 <50ms 측정

**Audit**:
- Fixture JSONL (30일치) → 예상 리포트
- 빈 로그 → graceful fallback
- Overlap: 알려진 pair에서 임계값 테스트

**Curate**:
- `--batch` 모드로 입출력 테스트
- 결정 로그 append 검증

**진입점**: `~/.claude/bin/tests/` 배치, `make test-skills`.

## Rollout (4 Phase)

**Phase 1 — Scanner (1일)**
- `skills-scan.py` 구현
- `/skills-catalog` slash cmd
- 검증: 158개 전부 파싱

**Phase 2 — Logger (1일)**
- `skills-log.sh` + `settings.json` hook 등록
- 1주일 로그 수집 (audit 없이 관찰만)
- 검증: 실제 Skill 호출이 JSONL 기록됨

**Phase 3 — Audit (1일)**
- `skills-audit.py` + `/skills-audit`
- 검증: 수집 로그로 top/unused 리포트

**Phase 4 — Curate (1일)**
- `skills-curate.py` + `/skills-curate`
- SKILLS-DECISIONS.md 초기화
- 검증: 대화형 workflow + 결정 append

### Rollback

- Hook 제거: `settings.json`의 PostToolUse 엔트리 삭제
- 파일 제거: `~/.claude/bin/skills-*`, `~/.claude/logs/skills-*`, slash cmd 3개

## Dependencies

- Python 3.11+ (stdlib only)
- `jq` (hook shell JSON 파싱)
- `settings.json` 변경 (hook 1개 추가)

## 활용 가이드

### 일상 사용 패턴

**매주 금요일 5분 루틴**:
```
/skills-audit
```
→ 이번 주 top 5 + 30일 unused. "이건 쓸 수 있었는데" 발견 지점.

**새 작업 시작 시**:
```
/skills-catalog
```
→ SKILLS-INDEX.md 열림. 카테고리별 탐색.

**월 1회 정리 (30분)**:
```
/skills-curate
```
→ unused/overlap 하나씩 결정. 파일 작업은 출력된 명령 수동 실행.

### 구체 시나리오

**시나리오 1: 존재 모름 (A 해결)**
- obsidian 작업 시작 → `/skills-catalog` → "## obsidian" 섹션 15개 리스트 → `obsidian:summarize-article` 발견

**시나리오 2: 중복 정리 (D 해결)**
- `/skills-audit` → "overlap: find-session ↔ agf (78%)"
- `/skills-curate` → 둘 다 필요 → `(d) distinct` → 경계 메모
- 다음 audit에서 재경고 안 됨

**시나리오 3: 노후 발견 (C+D 해결)**
- `/skills-audit --unused` → `old-helper` 6개월 미호출
- `/skills-curate` → `(a) archive` → `~/.claude/skills-archive/` 이동

### 학습 곡선

| 기간 | 숙련도 |
|------|--------|
| 첫날 | `/skills-catalog`로 훑기 |
| 1주차 | `/skills-audit` top N 확인 |
| 1개월차 | unused/overlap 충분, 첫 `/skills-curate` |
| 3개월차 | DECISIONS.md 기반으로 audit 노이즈 감소 |

### 실패 패턴 (피해야 할 것)

- Phase 2만 깔고 audit 잊기 → 로그만 쌓임. **금요일 캘린더 알림 추천**
- Curate에서 전부 `keep` 처리 → 정리 목적 상실. **30일 미호출 + keep은 이유 메모 필수**
- 매번 catalog 읽기 → 피로. **새 작업 시작할 때만, 평소엔 audit만**
