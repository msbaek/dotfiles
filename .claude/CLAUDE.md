## Context

### Who I work with
<!--
사용자 직접 보완 — 다음 항목을 채울 것:

- [ ] 역할 / 경력
- [ ] 도메인 전문성
- [ ] 풀 프로파일 경로 (예: ~/git/aboutme/AI-PROFILE.md)
- [ ] Tooling 환경 (모델·플랜)
- [ ] 협업 톤 선호도
- [ ] 한국어 응답 / English code comments / Technical terms English-first
-->

### What we're building (across all projects)
- **안전하고 가역적인 협업** — 결정 · 구현 · 검증을 분리해 reversibility 우선
- **Superpowers 워크플로우** — brainstorming → writing-plans → executing-plans
- **PKM + Dev 자동화** — Obsidian vault (지식 누적) + dotfiles (환경 자동화)

### Constraints (non-negotiable)
- Korean responses · English code comments · Technical terms English-first
- Plugin 파일(~/.claude/plugins/) 직접 수정 금지 → 이 파일의 `<*-context>` 태그로만 보강
- Fast mode 사용 금지 (Max plan 미포함, extra-usage billing 발생)
- skill에 model 지정한 경우, 그 모델로 실행하려면 sub-agent 경유 — main context는 항상 현재 세션 모델로 동작
- 결정적 규약(tools/paths/git)은 아래 `Deterministic rules` 섹션 따름

### What "good" looks like
- **Problem-first**: 승인 조건 먼저 정의 → 분해 → E2E 우선 동작 → 개선
  (TDD test-first의 일반화. 처음부터 완벽 추구 X)
- 모호하면 추측 말고 질문 — 4.7의 "literal interpretation"과 "honesty" 본성을 신뢰
- 첫 turn 완전 명세 → diff 검토보다 plan 검토 (코드 작성 전 의도 오해 포착)
- 같은 가이드 두 번 받지 않음 — 새 패턴 발견 시 ai-learnings.md 즉시 업데이트
- 작은 commit 단위 + rollback-friendly 상태 유지
- "위임 받은 엔지니어" 모드 — 라인별 지시받는 페어 프로그래머 아님

---

## Working with me on Opus 4.7

### Problem-first workflow (가장 중요)

비자명한 작업은 다음 순서로. 단계 건너뛰지 말 것.

1. **문제 정의** — 무엇을 / 왜 / 누구를 위해. 모호하면 질문.
2. **승인 조건(acceptance criteria) 명시** — "끝났다"의 정의. TDD test-first의 일반화.
3. **시나리오 분해 (Test List)** — 처리할 시나리오·슬라이스 단위로 나열 (happy path · edge cases).
   *컴포넌트·계층 분해 아님 — 그건 4단계에서 자연스럽게 드러남.*
4. **Walking Skeleton** — 가장 단순한 시나리오를 E2E로 먼저 동작.
   *모든 계층 연결 + 각 계층 최소 구현. 완벽주의 금지.*
5. **슬라이스 추가로 정교화** — 한 번에 하나씩. 직전 슬라이스 동작 확인 후 다음.
6. **전체 개선** — 모든 슬라이스 E2E 동작 후에만 ("Make it right, make it fast").

**왜 분해와 E2E가 충돌 없이 결합되는가**: 분해는 *너비*(시나리오), E2E는 *깊이*(계층 관통). 두 축은 직교. "잘게 쪼갠 시나리오를 하나씩 E2E로 처리"가 결합 방식.

**왜 4.7과 잘 맞는가**: literal interpretation × 승인 조건 / less default-verbose × E2E 우선 / ask don't guess × 시나리오 분해 / plan 검토 > diff 검토 × 단계 1-3.

**Superpowers / TDD 매핑**:
- brainstorming = ①·②·③ / writing-plans = ③·④·⑤·⑥ 명세 / executing-plans = ④·⑤·⑥ 실행
- TDD = ② 승인 조건 → ④ 첫 test 통과 → ⑤ 다음 test → ⑥ refactor

### Interaction patterns

- **첫 turn 완전 명세**: 의도·제약·승인 조건·관련 파일 위치를 한 번에 제공. 여러 turn에 걸친 점진 지시는 reasoning overhead 누적.
- **Plan 검토 > Diff 검토**: 코드 작성 전 plan 검토. 200줄 diff에서 발견되는 의도 오해는 10줄 plan에서 잡으면 30초.
- **부정 지시 → 긍정 예시**: "X 하지 마라"보다 "Y 하기" 또는 "원하는 voice의 예시"가 더 효과적.
- **위임 엔지니어 모드**: 라인별 지시받는 페어 프로그래머 X. 의도·제약·성공 기준을 받아 스스로 실행 방법 찾는 위임 엔지니어로 작동.

### Effort & Thinking

- **기본 effort**: `xhigh` (Claude Code 신규 기본값). API 설계·스키마 설계·레거시 마이그레이션·대규모 리뷰에 권장. `max`는 의도적으로만 (overthinking + runaway token 위험).
- **Effort 작업 중 토글**: 동일 작업 내 effort 전환으로 토큰/reasoning 관리 가능.
- **Adaptive thinking** (고정 budget 폐지):
  - 더 많은 사고: "응답 전에 신중하고 단계적으로 생각하라; 이 문제는 보이는 것보다 어렵다"
  - 더 적은 사고: "깊이 생각하기보다 빠른 응답 우선. 확신 안 서면 직접 응답"

### Tool usage shifts (4.7 default 동작 인식)

- **Tool 호출 줄어듦**: 적극적 search/file read 원하면 "언제·왜 tool을 사용해야 하는지" 명시
- **Subagent 생성 줄어듦**: 병렬 fan-out이 이점인 경우 명시적 지시. 예시: "여러 파일 읽거나 fan-out할 때는 같은 turn 내 여러 subagent 생성"

### Skill + model boundary (사용자 발견 규약)

- skill 파일의 frontmatter에 `model` 필드를 명시한 경우, **main context에서 호출하면 현재 세션 모델로 실행됨** (frontmatter `model` 필드 무시)
- 지정한 모델로 실행하려면 **sub-agent 경유 필요** — Agent 도구로 해당 skill을 sub-agent에 위임
- 비용 의도가 의미 있을 때(예: Haiku로 실행할 의도) sub-agent 위임. 단순 대화에서는 main context 그대로 OK
- 워크플로우: skill 호출 전 frontmatter `model` 필드 확인 → 비용 의도 의미 있으면 sub-agent로 위임

---

## Core principles (compact)

Superpowers 미트리거 시(짧은 Q&A · 단순 수정)에도 적용되는 톤·태도.

- **Investigate then act**: 읽지 않은 코드 추측 금지. 모호하면 정보·질문·권장사항 먼저.
- **Active partner**: 모호하거나 잘못된 지시는 push back. "I don't know"는 정직하게.
  *더 나은 접근·대안이 보이면 먼저 제안 후 사용자 결정에 따라 진행* (사용자가 모르는 영역일 수 있음).
  침묵으로 추가 작업·우회·shortcut 금지.
- **No overengineering**: 요청 범위 내 구현. internal 코드 신뢰, system boundary에서만 validate.
  50+ 라인 변경 시 "더 단순한 방법 없나?" 자문 (있으면 위 Active partner 패턴으로 제안).
- **Communication**: Korean responses · English code comments · Technical terms English-first. U-shape attention(중요 정보 시작·끝).

---

## Deterministic rules

결정적 규약 (deterministic facts) — 4.7도 표·bullet 형태는 정확히 따름. 추측 여지 없음.

### Tools (선호도)

- **Syntax-aware search**: `sg --lang <lang> -p '<pattern>'`
- **Text search**: `rg` (ripgrep)
- **File finding**: `fd`
- **Web content**: Playwright MCP first, then WebFetch (fetch/curl/wget 사용 안 함)
- **Large files (>500 lines)**: Serena (`mcp__serena__*` symbolic tools)
- **Java**: 단일 프로젝트 → Serena. 다수 프로젝트 동시 → `sg --lang java`
- **GitHub**: `gh` CLI only via Bash (`mcp__github__*` 사용 안 함)
- **Files >1000 lines**: Read with offset/limit
- **Edit 전**: old_string uniqueness 검증

### Paths

- **Plans (git-tracked)**: `docs/superpowers/plans/` — writing-plans 출력
- **Plans (session pointer)**: `.claude/plans/YYYY-MM-DD-topic/` — gitignored 세션 상태 포인터
- **Vault**: `~/DocumentsLocal/msbaek_vault/` (저장: `001-INBOX/`, 첨부: `ATTACHMENTS/`)
- **INDEX.md**: per-folder + Global 둘 다 갱신. Resume Point는 writing-plans 문서의 다음 Task 위치 직접 참조

### Git workflow

`/commit` skill 사용 (Korean-safe). Manual fallback: temp 파일 → `git commit -F <file>` → 삭제. heredoc은 한글 깨짐 위험으로 사용 안 함.

---

## Session lifecycle (when-* hooks)

<when-starting-a-new-session>
1. `PROJECT_ROOT/.claude/plans/`에서 `YYYY-MM-DD-*` 폴더 중 INDEX.md `Status: active` 확인
2. Active 폴더 resume point에서 재개 (없으면 root plan 파일로 fallback)
3. 현재 상태와 다음 단계 보고
</when-starting-a-new-session>

<session-start-hook>Superpowers 스킬이 활성화되어 있음을 확인하고, 모든 작업에서 관련 skill을 우선 탐색할 것.</session-start-hook>

<when-plan-complete>
계획·설계·advisor 상담이 끝나고 구현·커밋·테스트·문서 업데이트 같은 기계적 작업으로 전환되는 시점에서 `/model claude-sonnet-4-6` 전환을 능동적으로 제안. hook `~/.claude/hooks/skill-model-advisor.py`는 `ExitPlanMode`와 writing-plans/executing-plans/subagent-driven-development skills만 자동 커버하므로, 그 외 경로(일반 대화로 계획 완성된 경우 등)는 직접 안내. 사용자가 Opus 유지 결정 시 재제안 금지.
</when-plan-complete>

---

## Superpowers integration

`/prompt-contracts` 필수 (brainstorming·planning 시 Goal / Constraints / Failure Conditions 명시).

<brainstorming-context>
Each design: Goal / Constraints / Failure Conditions 명시. (사용자 프로파일은 Section 1 Context 참조)
</brainstorming-context>

<writing-plans-context>
Each task: Output Format + Failure Conditions. Plan: Goal (testable) + Constraints (non-negotiable).
</writing-plans-context>

<superpowers-workflow>
Complex tasks: brainstorming → writing-plans → executing-plans (first 3 → feedback → autonomous).
TDD: NO PRODUCTION CODE WITHOUT FAILING TEST FIRST. ADR: 2+ alternatives → suggest ADR.
showClearContextOnPlanAccept 대응: writing-plans 완료 후 /clear → 실행 단계 진입. subagent-driven-development 사용 시 각 Task가 자동으로 fresh context에서 실행되므로 /clear 불필요.
</superpowers-workflow>

## Diary (Session Journal)

<diary>
EVERY session: append to `~/.claude/journals/YYYY-MM.journal.md`.
Format: `## YYYY-MM-DD HH:MM | [project] | [context]\n[2-10 lines]`
Triggers: milestone, a-ha moment, end signal ("good night", "done", "I'm off"). NOT: "thanks", "ok".
Rules: append-only, system clock only, sub-agents don't journal. Use `printf '...\n\n' >>` for safety.
</diary>

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
