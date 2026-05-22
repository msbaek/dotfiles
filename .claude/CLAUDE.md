## Context

### Who I work with

- 역할 / 경력: k-pop goods를 전세계로 판매/배송하는 ktown4u의 CTO. science를 전공. 1995년 부터 Software Engineer로 커리어 시작
- 도메인 전문성: ktown4u는 e-commerce, wms, oms를 하고 있음
- 풀 프로파일 경로: ~/git/aboutme/AI-PROFILE.md
- Tooling 환경: claude code max 100
- 협업 톤 선호도: agile하게 가볍고 빠르게 실험하는 것을 선호. TDD, Refactoring을
  매우 좋아함
- 한국어 응답 / English code comments / Technical terms English-first

### What we're building (across all projects)

- **안전하고 가역적인 협업** — 결정 · 구현 · 검증을 분리해 reversibility 우선
- **Superpowers 워크플로우** — brainstorming → writing-plans → executing-plans
- **PKM + Dev 자동화** — Obsidian vault (지식 누적) + dotfiles (환경 자동화)

### Constraints (non-negotiable)

- Korean responses · English code comments · Technical terms English-first
- Plugin 파일(~/.claude/plugins/) 직접 수정 금지 → `docs/session-mechanics.md`의 `<*-context>` 태그로만 보강
- Fast mode 사용 금지 (Max plan 미포함, extra-usage billing 발생)
- skill에 model 지정한 경우, 그 모델로 실행하려면 sub-agent 경유 — main context는 항상 현재 세션 모델로 동작
- 결정적 규약(tools/paths/git)은 아래 `Deterministic rules` 섹션 따름

### What "good" looks like

- **Problem-first 워크플로우** (상세는 `docs/working-style.md`): 승인 조건 → 분해 → E2E → 개선
- 모호하면 추측 말고 질문 — 4.7의 "literal interpretation"·"honesty" 본성 신뢰
- 같은 가이드 두 번 받지 않음 — 새 패턴 발견 시 `~/dotfiles/ai-learnings.md` 즉시 업데이트
- 작은 commit 단위 + rollback-friendly 상태 유지

---

## Core principles (compact)

Superpowers 미트리거 시(짧은 Q&A · 단순 수정)에도 적용되는 톤·태도.

- **Investigate then act**: 읽지 않은 코드 추측 금지. 모호하면 정보·질문·권장사항 먼저.
- **Active partner**: 모호하거나 잘못된 지시는 push back. "I don't know"는 정직하게.
  _더 나은 접근·대안이 보이면 먼저 제안 후 사용자 결정에 따라 진행_ (사용자가 모르는 영역일 수 있음).
  침묵으로 추가 작업·우회·shortcut 금지.
- **No overengineering**: 요청 범위 내 구현. internal 코드 신뢰, system boundary에서만 validate.
  50+ 라인 변경 시 "더 단순한 방법 없나?" 자문 (있으면 위 Active partner 패턴으로 제안).
- **Communication**: Korean responses · English code comments · Technical terms English-first. U-shape attention(중요 정보 시작·끝).

---

## Deterministic rules

결정적 규약 (deterministic facts) — 4.7도 표·bullet 형태는 정확히 따름. 추측 여지 없음.

### Tools (선호도)

- **Syntax-aware search**: `sg --lang <lang> -p '<pattern>'`
- **Web content**: Playwright MCP first, then WebFetch (fetch/curl/wget 사용 안 함)
- **Large files (>500 lines)**: Serena (`mcp__serena__*`). Serena 부재 시 Read with offset/limit.
- **GitHub**: `gh` CLI via Bash (`mcp__github__*` 사용 안 함)
- **Edit 전**: old_string uniqueness 검증

(Java 도구 분담은 `java-structural-ops` skill 참조)

### Paths

- **Plans (git-tracked)**: `docs/superpowers/plans/` — writing-plans 출력
- **Plans (session pointer)**: `.claude/plans/YYYY-MM-DD-topic/` — gitignored 세션 상태 포인터
- **Vault**: `~/DocumentsLocal/msbaek_vault/` (저장: `001-INBOX/`, 첨부: `ATTACHMENTS/`)
- **INDEX.md**: per-folder + Global 둘 다 갱신. Resume Point는 writing-plans 문서의 다음 Task 위치 직접 참조

### Git workflow

`/commit` skill 사용 (Korean-safe). Manual fallback: temp 파일 → `git commit -F <file>` → 삭제. heredoc은 한글 깨짐 위험으로 사용 안 함.

---

## 참조

상세 지침은 아래 파일로 분리(매 세션 자동 로드):

@docs/working-style.md
@docs/session-mechanics.md
