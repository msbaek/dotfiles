# Skills Catalog 사용법

> 150+ Claude Code skills 발견(Discoverability) · 감사(Audit) · 정리(Curation) 통합 시스템
> **작성일**: 2026-04-17

---

## 빠른 시작

```bash
# 1. 카탈로그 생성/새로고침
/skills-catalog

# 2. 최근 30일 사용량 리포트
/skills-audit

# 3. 결정 기록 대화형
/skills-curate
```

---

## 3개 슬래시 명령어

### `/skills-catalog` — 카탈로그 생성

모든 설치된 skill의 frontmatter를 스캔 → 카테고리별 인덱스 생성.

**산출물:**
- `~/.claude/SKILLS-INDEX.md` (사람이 읽는 마크다운)
- `~/.claude/skills-index.json` (도구용 JSON)

**사용 시점:**
- 새 작업 시작 — 어떤 skill 있는지 훑기
- 플러그인 설치/제거 후 — 카탈로그 새로고침

**CLI 직접 실행:**
```bash
~/.claude/bin/skills-scan.py              # 기본
~/.claude/bin/skills-scan.py --json       # stdout JSON
```

---

### `/skills-audit` — 사용량 감사

`~/.claude/logs/skills-usage.jsonl` 분석 → top/unused/overlap/stale 리포트.

**기본 30일:**
```bash
/skills-audit
```

**기간 지정:**
```bash
/skills-audit 60      # 60일
/skills-audit 7       # 지난 주
```

**필터 옵션 (CLI):**
```bash
~/.claude/bin/skills-audit.py --days 30              # 기본
~/.claude/bin/skills-audit.py --json                 # curate 입력용
~/.claude/bin/skills-audit.py --unused-only          # unused만
~/.claude/bin/skills-audit.py --overlap-threshold 0.8  # 기본 0.7
```

**리포트 4개 섹션:**
| 섹션 | 의미 |
|------|------|
| **Top** | 호출 횟수 Top 10 |
| **Unused** | 30일 내 한 번도 호출 안 된 skill |
| **Overlap** | description 유사도 ≥ 0.7 pair |
| **Stale** | 6개월 이상 수정 + 호출 0 |

---

### `/skills-curate` — 결정 기록

Audit 결과의 unused/overlap 건을 하나씩 결정 → `SKILLS-DECISIONS.md`에 기록.

**대화형 시작:**
```bash
/skills-curate
```

**중단 후 재개:**
```bash
/skills-curate --resume
```

**상태 초기화:**
```bash
/skills-curate --reset
```

**Unused 선택지:**
| 키 | 동작 |
|----|------|
| `k` | keep (유지, 이유 필수) |
| `a` | archive (이동 예정) |
| `d` | delete (삭제 예정) |
| `n` | note (메모만 남기고 보류) |
| `s` | skip (이번엔 건너뜀) |

**Overlap 선택지:**
| 키 | 동작 |
|----|------|
| `m` | merge (둘을 합칠 예정) |
| `k1` | keep_first (첫 번째만 유지) |
| `k2` | keep_second (두 번째만 유지) |
| `d` | distinct (둘 다 유지, 이유 메모 필수) |
| `s` | skip |

**주의:** 결정만 기록. 파일 이동/삭제는 수동 실행.

```bash
# archive
mkdir -p ~/.claude/skills-archive
mv ~/.claude/skills/<name> ~/.claude/skills-archive/

# delete
rm -rf ~/.claude/skills/<name>
```

---

## 일상 루틴

### 매주 금요일 5분

```bash
/skills-audit
```

→ 이번 주 top N 확인. "이거 쓸 수 있었는데" 발견 지점.

### 새 작업 시작 시

```bash
/skills-catalog
```

→ `SKILLS-INDEX.md` 열기. 카테고리별 탐색.

### 월 1회 30분

```bash
/skills-curate
```

→ unused/overlap 하나씩 결정. 출력된 명령을 수동 실행.

---

## 파일 구조

```
~/.claude/
├── bin/
│   ├── skills-scan.py              # Scanner
│   ├── skills-log.sh               # Hook logger
│   ├── skills-audit.py             # Audit
│   ├── skills-curate.py            # Curate
│   └── tests/
│       ├── test_skills_scan.py
│       ├── test_skills_audit.py
│       ├── test_skills_curate.py
│       ├── test_skills_log.sh
│       └── fixtures/
├── commands/
│   ├── skills-catalog.md           # /skills-catalog
│   ├── skills-audit.md             # /skills-audit
│   └── skills-curate.md            # /skills-curate
├── logs/
│   └── skills-usage.jsonl          # 사용 로그 (append-only)
├── SKILLS-INDEX.md                 # 카탈로그 (auto-gen)
├── SKILLS-DECISIONS.md             # Curation 기록
├── skills-index.json               # 도구용 JSON
├── .skills-curate-state.json       # --resume 상태
└── settings.json                   # PostToolUse hook 등록
```

---

## 동작 원리

### 데이터 흐름

```
SKILL.md (207개)
    ↓ skills-scan.py (수동)
skills-index.json ──→ SKILLS-INDEX.md    ← 발견

Skill tool 호출
    ↓ PostToolUse hook
skills-usage.jsonl ──→ /skills-audit     ← 감사

catalog + log
    ↓ Jaccard 유사도 + 키워드
overlap pair    ──→ /skills-curate       ← 정리
    ↓
SKILLS-DECISIONS.md (append-only)
```

### PostToolUse Hook

`~/.claude/settings.json`에 등록됨:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/bin/skills-log.sh"
          }
        ]
      }
    ]
  }
}
```

Skill tool 호출마다 `skills-log.sh`가 JSONL 한 줄 append. 실패해도 silent (exit 0).

### 로그 레코드 형식

```jsonl
{"ts":"2026-04-17T10:15:03Z","skill":"superpowers:brainstorming","project":"~/dotfiles","trigger":"user"}
```

---

## 학습 곡선

| 기간 | 숙련도 |
|------|--------|
| 첫날 | `/skills-catalog`로 훑기 |
| 1주차 | `/skills-audit` top N 확인 |
| 1개월차 | unused/overlap 충분히 축적, 첫 `/skills-curate` |
| 3개월차 | `SKILLS-DECISIONS.md` 기반 audit 노이즈 감소 |

---

## 실패 패턴

**피해야 할 것:**
- Hook만 등록하고 audit 잊기 → 로그만 쌓임. **금요일 캘린더 알림 권장**
- Curate에서 전부 `keep` → 정리 목적 상실. **30일 미호출 + keep은 이유 필수**
- 매번 `/skills-catalog` → 피로. **새 작업 시작 시에만, 평소는 audit만**

---

## Rollback

문제 발생 시 전체 롤백:

```bash
# Hook 제거
python3 - <<'PY'
import json
from pathlib import Path
path = Path.home() / ".claude" / "settings.json"
data = json.loads(path.read_text(encoding="utf-8"))
data["hooks"]["PostToolUse"] = [
    e for e in data["hooks"].get("PostToolUse", [])
    if not (isinstance(e, dict) and e.get("matcher") == "Skill"
            and any("skills-log.sh" in h.get("command", "") for h in e.get("hooks", [])))
]
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

# 파일 제거
rm -f ~/.claude/bin/skills-scan.py ~/.claude/bin/skills-log.sh
rm -f ~/.claude/bin/skills-audit.py ~/.claude/bin/skills-curate.py
rm -rf ~/.claude/bin/tests
rm -f ~/.claude/commands/skills-catalog.md ~/.claude/commands/skills-audit.md ~/.claude/commands/skills-curate.md
rm -f ~/.claude/SKILLS-INDEX.md ~/.claude/skills-index.json ~/.claude/SKILLS-DECISIONS.md
rm -rf ~/.claude/logs/skills-usage*.jsonl*
rm -f ~/.claude/.skills-curate-state.json
```

---

## 관련 문서

- Spec: `docs/superpowers/specs/2026-04-17-skills-catalog-design.md`
- Plan: `docs/superpowers/plans/2026-04-17-skills-catalog.md`
- Branch: `feat/skills-catalog` (16 commits)
