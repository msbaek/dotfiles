# CLAUDE.md Opus 4.7 적합성 개선 설계

## Goal

글로벌 `~/.claude/CLAUDE.md`를 Opus 4.7의 본성(literal interpretation, ask don't guess, less default-verbose, tool calls less often)에 정합하도록 재구성하여:

- 4.7이 첫 turn부터 "큰 그림(의도·제약·성공 기준)"을 잡을 수 있게 한다
- 4.7의 리터럴 해석 본성과 충돌하는 처방적·부정형 지시를 긍정 예시·맥락으로 재작성한다
- 검증된 운영 규약(도구 선호도·경로·Git 워크플로우)은 표/bullet 형태로 보존한다
- 매 세션 글로벌 CLAUDE.md에 자동 로드되는 conditional 컨텍스트는 외부 위치(skill·project CLAUDE.md)로 분리한다

## Background

### Opus 4.7 핵심 변화

vault 자료(`003-RESOURCES/AI/CLAUDE-CODE/opus-4-7-differeces.md`, `Pawel-Huryn-Opus47-프롬프팅-전략-변화.md`, `Claude-Code-Opus-4.7-Best-Practices.md`, `Claude-Opus-4.7-리터럴-해석과-프롬프트-엔지니어링-변화.md`)에서 검증된 4.7 패러다임 전환:

- **지시 따르기**: 자의적 해석·순서 변경 → 문자 그대로 엄격하게 따름
- **의도 추론**: 암묵적 추측 → 모르는 것은 묻기 ("ask don't guess")
- **정신 상태**: "스마트해 보임" → "정직함" (날조 감소)
- **응답 길이**: default-verbose → 작업 복잡도에 calibrated
- **Tool 호출**: 적극적 → 보수적 (reasoning 우선)
- **Subagent 생성**: 적극적 → 판단적 (judicious)
- **기본 effort**: high → xhigh (Claude Code 신규 기본값)
- **Thinking**: 고정 budget → adaptive (모델이 단계별 자율 판단)

### 현재 CLAUDE.md(192줄) 페인포인트

사용자 진단:
- **C (주 동기)**: 4.7의 효능 미발휘 — 위임 엔지니어 모드가 아닌 페어 프로그래머 모드로 다뤄짐
- **B (부 동기)**: 부정 지시("절대 쓰지 말 것", "Never use") 산재 → 4.7의 리터럴 해석 위험

추가 발견:
- skill에 model 지정해도 main context에서 호출하면 무시됨 → sub-agent 경유 필요
- 일부 섹션은 superpowers skill과 책임 중복 (Action Principles, Augmented Coding, Quality Control, Long-running Tasks, Context Health, Subagent Orchestration)
- 일부 섹션은 모든 세션에 자동 로드될 필요 없는 conditional 컨텍스트 (Java 작업, Obsidian 문서 생성)
- "Claude 세션 검색" 표는 skill description으로 이미 자동 트리거됨 → 중복

## Constraints (non-negotiable)

- 글로벌 CLAUDE.md 위치 (`~/.claude/CLAUDE.md` ≡ `~/dotfiles/.claude/CLAUDE.md`)는 변경하지 않는다 (stow 심볼릭 링크 유지)
- 검증된 결정적 규약(tool 선호도·path 규약·Git 워크플로우)은 보존한다
- Superpowers 워크플로우(brainstorming → writing-plans → executing-plans)와 충돌하지 않는다
- Vault CLAUDE.md(`~/DocumentsLocal/msbaek_vault/CLAUDE.md`)의 기존 내용(Zettelkasten·디렉토리 메타)은 보존한다
- Plugin 파일(`~/.claude/plugins/`) 직접 수정 금지 — 신규 skill은 사용자 글로벌 위치(`~/.claude/skills/`)에만 생성한다
- 한글 응답·영문 코드 주석·기술 용어 영문 우선 규약 유지

## Failure Conditions

- 4.7이 새 CLAUDE.md를 받고도 "위임 엔지니어 모드"로 동작하지 않으면 (예: 라인별 지시 필요) → 재작성 실패
- 글로벌 CLAUDE.md 길이가 200줄을 초과하면 (목표 110-140줄) → 슬림화 실패
- skill description-based discovery가 작동 안 해서 Java 또는 Obsidian 워크플로우가 자동 트리거되지 않으면 → 분리 실패
- 기존에 잘 작동하던 운영 규약(예: `/commit` skill, Plan Mode, advisor 호출, Git heredoc 회피)이 누락되면 → 회귀
- Sonnet 4.6과의 호환성 손실 (모델 라우팅 후에도 잘 따라야 함) → 호환성 실패

## Out of Scope

- Vault CLAUDE.md 본문 재작성 (Forward Related Notes 워크플로우만 skill로 분리)
- 5개 Java 프로젝트 각각의 project-level CLAUDE.md 생성·수정
- Superpowers plugin 자체 수정 (overlay tag 방식만 사용)
- Sonnet 4.6 전용 별도 CLAUDE.md 분기 (단일 파일에서 양 모델 호환)
- 자동 모델 전환 hook 신규 구현 (기존 `skill-model-advisor.py`만 유지)

## Architecture

### Hybrid 접근 방식

```
┌─────────────────────────────────────────────────────────────┐
│ Global CLAUDE.md (~/.claude/CLAUDE.md)                      │
│ ─ 매 세션 자동 로드 ─                                         │
│                                                              │
│  Section 1: Context (4-블록)                                 │
│  Section 2: Working with me on Opus 4.7                      │
│  Section 3: Core principles (compact, superpowers backup)   │
│  Section 4: Deterministic rules (Tools/Paths/Git)           │
│  Section 5: Session lifecycle (when-starting, when-plan-end) │
│  Section 6: Superpowers integration + Diary                 │
└─────────────────────────────────────────────────────────────┘
        │                      │                      │
        ▼                      ▼                      ▼
┌──────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Vault CLAUDE.md  │  │ obsidian-      │  │ java-          │
│ (dir-based       │  │ document-      │  │ structural-ops │
│  auto-load)      │  │ workflow skill │  │ skill          │
│                  │  │ (description   │  │ (description   │
│ vault 디렉토리·   │  │  trigger)      │  │  trigger)      │
│ Zettelkasten     │  │                │  │                │
│ 메타만           │  │ Forward        │  │ 단일=Serena    │
│                  │  │ Related Notes  │  │ 다수=sg        │
└──────────────────┘  └────────────────┘  └────────────────┘
```

### Section Map (이전 192줄 → 이후 ~135줄)

| 이전 섹션 | 처리 | 신규 위치 |
|-----------|------|-----------|
| Ground Rule (P0/P1/P2) | 제거 (Outline의 의미는 신규 Outline에 흡수) | — |
| Session Management (when-starting) | 유지 (압축) | Section 5 |
| Tool Preferences | 유지 (Java 한 줄 추가) | Section 4 |
| Claude 세션 검색 표 | **제거** (skill description 중복) | — |
| 모델 라우팅 (50% 자동 전환) | **제거** (실행 불가능 룰) | — |
| `<when-plan-complete>` hook | 유지 | Section 5 |
| Action Principles | 압축 | Section 3 (1 bullet) |
| Augmented Coding (active partner) | 압축 | Section 3 (1 bullet, 강화) |
| `<noise_cancellation>` | 흡수 (Communication에) | Section 3 |
| Quality Control | 압축 | Section 3 (1 bullet) |
| Long-running Tasks | **제거** (auto-compaction이 처리) | — |
| Context Health | **제거** (모델 메타인지 자동 처리) | — |
| Collaboration Patterns | **제거** (superpowers `dispatching-parallel-agents` 강제) | — |
| Communication | 압축 | Section 3 (1 bullet) |
| Work Patterns | 압축 (paths만 유지) | Section 4 |
| Git Workflow | 유지 (압축) | Section 4 |
| Verification (Completion Gate) | **제거** (superpowers `verification-before-completion` 강제) | — |
| Obsidian Vault `<when-creating-obsidian-document>` | **외부 이동** | `obsidian-document-workflow` skill |
| LSP-First `<when-java-project>` | **외부 이동** | `java-structural-ops` skill |
| Learning | **제거** (Section 1 "good outcome"에 흡수) | Section 1 |
| Superpowers Integration | 유지 | Section 6 |
| Diary | 유지 (사용자 결정대로 그대로) | Section 6 |
| — (신설) | Context 4-블록 | **Section 1** |
| — (신설) | Working with me on Opus 4.7 (Problem-first workflow + Interaction patterns + Effort & Thinking + Tool usage shifts + Skill+model boundary) | **Section 2** |

### 책임 분리

| 위치 | 다루는 것 |
|------|-----------|
| Global CLAUDE.md | 모든 세션 공통 — Context·4.7 효능 가이드·결정적 규약·superpowers 미트리거 시 보호망 |
| Vault CLAUDE.md | vault working dir 진입 시만 — vault 디렉토리 의미·Zettelkasten 메타 |
| `obsidian-document-workflow` skill | Obsidian 문서 생성 컨텍스트 트리거 시 — Forward Related Notes 워크플로우 |
| `java-structural-ops` skill | Java 코드베이스 작업 컨텍스트 트리거 시 — 단일/다수 프로젝트별 도구 분담 |
| Superpowers skills | brainstorming/writing-plans/executing-plans 등 — 절차적 워크플로우 강제 |

## Detailed Section Designs

### Section 1: Context (4-블록)

```markdown
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
```

### Section 2: Working with me on Opus 4.7

```markdown
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
```

### Section 3: Core principles (compact)

```markdown
## Core principles (compact)

Superpowers 미트리거 시(짧은 Q&A · 단순 수정)에도 적용되는 톤·태도.

- **Investigate then act**: 읽지 않은 코드 추측 금지. 모호하면 정보·질문·권장사항 먼저.
- **Active partner**: 모호하거나 잘못된 지시는 push back. "I don't know"는 정직하게.
  *더 나은 접근·대안이 보이면 먼저 제안 후 사용자 결정에 따라 진행* (사용자가 모르는 영역일 수 있음).
  침묵으로 추가 작업·우회·shortcut 금지.
- **No overengineering**: 요청 범위 내 구현. internal 코드 신뢰, system boundary에서만 validate.
  50+ 라인 변경 시 "더 단순한 방법 없나?" 자문 (있으면 위 Active partner 패턴으로 제안).
- **Communication**: Korean responses · English code comments · Technical terms English-first. U-shape attention(중요 정보 시작·끝).
```

### Section 4: Deterministic rules

```markdown
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
```

### Section 5: Session lifecycle (when-* hooks)

```markdown
## Session lifecycle (when-* hooks)

<when-starting-a-new-session>
1. `PROJECT_ROOT/.claude/plans/`에서 `YYYY-MM-DD-*` 폴더 중 INDEX.md `Status: active` 확인
2. Active 폴더 resume point에서 재개 (없으면 root plan 파일로 fallback)
3. 현재 상태와 다음 단계 보고
</when-starting-a-new-session>

<when-plan-complete>
계획·설계·advisor 상담이 끝나고 구현·커밋·테스트·문서 업데이트 같은 기계적 작업으로 전환되는 시점에서 `/model claude-sonnet-4-6` 전환을 능동적으로 제안. hook `~/.claude/hooks/skill-model-advisor.py`는 `ExitPlanMode`와 writing-plans/executing-plans/subagent-driven-development skills만 자동 커버하므로, 그 외 경로(일반 대화로 계획 완성된 경우 등)는 직접 안내. 사용자가 Opus 유지 결정 시 재제안 금지.
</when-plan-complete>
```

### Section 6: Superpowers integration + Diary

```markdown
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
```

## Skill Specifications (new)

### obsidian-document-workflow

**위치**: `~/.claude/skills/obsidian-document-workflow/SKILL.md`

**Frontmatter**:
```yaml
---
name: obsidian-document-workflow
description: |
  Use when creating or updating an Obsidian markdown document (anywhere — vault dir or other projects).
  Adds Forward Related Notes section (top-5 hybrid search results) to the document after creation.
  Triggers on: "obsidian 문서 생성", "vault에 저장", "001-INBOX에 작성", "Obsidian markdown 작성",
  "Related Notes 추가", "vault 정리 후 백링크". Backward Related Notes는 별도 vis-backlink-trigger
  스킬이 처리하므로 이 스킬은 Forward만 책임진다.
---
```

**본문**:
```markdown
# Obsidian Document Workflow (Forward Related Notes)

Obsidian 문서 A를 생성·정리한 직후 자동 실행.

## Forward Related Notes 추가 절차

1. **검색**: vault-intelligence hybrid search 호출
   ```bash
   curl -s --get --data-urlencode "query=<A-title>" \
     "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=10"
   ```
   서버 미실행 시 fallback: `vis search "<A-title>" --rerank --top-k 10`

   *A-title 결정*: frontmatter `title` 필드 우선, 없으면 첫 `# 헤딩` 텍스트.

2. **선별**: 결과에서 다음 제외
   - 자기 자신 (A 문서 본인)
   - daily notes (`notes/dailies/`)
   - 관련도 점수 0 이하

3. **상위 5개 자동 추가** (사용자가 inbox 검토 시 수정하므로 별도 승인 불필요)

4. **문서 하단 형식**:
   ```markdown
   ## Related Notes

   - [[Note-Title-1]] — 한 줄 맥락 설명
   - [[Note-Title-2]] — 한 줄 맥락 설명
   ...
   ```

5. **frontmatter `related:` 필드**: 명시 요청 시에만 업데이트 (기본은 본문 섹션만 추가)

## Backward Related Notes (이 스킬 책임 아님)

Backward(다른 문서들이 A를 가리키도록)는 `/obsidian:add-tag` 또는 `/obsidian:add-tag-and-move-file`이
마지막 단계에서 `vis-backlink-trigger` 스킬로 처리한다.
상세: `~/git/vault-intelligence/docs/superpowers/specs/2026-04-26-vis-backlink-smart-trigger-design.md`
```

### java-structural-ops

**위치**: `~/.claude/skills/java-structural-ops/SKILL.md`

**Frontmatter**:
```yaml
---
name: java-structural-ops
description: |
  Use when working with Java codebase — navigation, refactoring, cross-project search.
  Java 프로젝트(특히 5개 규모 multi-project) 작업 시 토큰·속도 절약을 위해 구조 도구 우선 사용.
  단일 프로젝트는 Serena (mcp__serena__*) — find_symbol, find_referencing_symbols, rename_symbol 등.
  다수 프로젝트 동시 검색은 sg --lang java -p '<pattern>'.
  Triggers on: "Java 작업", "Java refactor", "Java 클래스 검색", "find_symbol", "find_referencing_symbols",
  "rename in Java", "Java 다중 프로젝트", "Java multi-project", "Spring Boot navigation",
  "Java 호출 그래프", "incomingCalls", "outgoingCalls".
---
```

**본문**:
```markdown
# Java Structural Operations

Java 프로젝트 작업 시 토큰·속도 절약을 위해 구조 도구 우선.
*Serena는 LSP 기반 semantic 분석, sg는 tree-sitter AST 기반 syntactic search.*

## 도구 분담 (프로젝트 개수 기준)

### 단일 프로젝트: Serena

- `mcp__serena__find_symbol` — 심볼 정의 위치
- `mcp__serena__find_referencing_symbols` — 호출처/사용처
- `mcp__serena__rename_symbol` — 심볼 일괄 rename
- `mcp__serena__get_symbols_overview` — 파일·디렉토리 심볼 트리
- `mcp__serena__incomingCalls` / `outgoingCalls` — 호출 그래프
- `mcp__serena__goToDefinition` / `documentSymbol` / `workspaceSymbol`

프로젝트 전환: `mcp__serena__activate_project` 호출

### 다수 프로젝트 동시: sg (ast-grep)

```bash
sg --lang java -p '<pattern>' <dir1> <dir2> <dir3> ...
```

- multi-dir 동시 검색 가능 (Serena는 한 번에 한 프로젝트만 활성화)
- tree-sitter AST 기반이라 `grep`보다 정확 (주석·문자열 false-positive 회피)
- 예시:
  ```bash
  sg --lang java -p '@Transactional' ~/git/proj1 ~/git/proj2
  sg --lang java -p '$CLASS extends $BASE' ~/git/{proj1,proj2,proj3}
  ```

## Grep 허용 범위

Java 본체 검색은 위 두 도구로. `rg`/`grep`은 다음에만:
- string literals
- config 파일 (yaml, properties, xml)
- 로그 파일
- 비-Java 파일
- <500 라인 작은 파일

## Fallback 정책

위 도구가 에러 반환 시:
1. 사용자에게 에러 보고
2. Grep 사용 허가 받음
3. 허가 받은 후 `rg` 또는 `sg` (다른 옵션) 시도

자동 fallback 금지 — 사용자가 의도된 도구를 알아야 다음 작업 결정 가능.
```

## Migration Plan

다음 순서로 진행. 각 단계 후 검증.

### Phase 1: Backup
1. 현재 글로벌 CLAUDE.md를 `~/.claude/CLAUDE.md.bak.2026-04-30`으로 백업

### Phase 2: 신규 글로벌 CLAUDE.md 작성
2. Section 1-6 통합본을 `~/.claude/CLAUDE.md`(== `~/dotfiles/.claude/CLAUDE.md`)에 작성
3. 길이 검증: 약 130-140줄

### Phase 3: 신규 Skill 2개 생성
4. `~/.claude/skills/obsidian-document-workflow/SKILL.md` 생성
5. `~/.claude/skills/java-structural-ops/SKILL.md` 생성

### Phase 4: 검증
6. 새 세션 시작 → SessionStart hook으로 자동 로드 확인
7. Available skills 목록에 신규 skill 2개 등록 확인
8. 4.7이 새 Context Block 인식 확인 (예: "What good looks like" 원칙 따름)

### Phase 5: 운영 평가 (1주)
9. 1주간 사용 후 다음 항목 평가:
   - 4.7이 "위임 엔지니어 모드"로 동작하는가?
   - skill description-based discovery 정확도 (false positive/negative)
   - 누락된 운영 규약 발견 시 즉시 보강

## Verification

설계 성공 기준 (Failure Conditions의 역):

- [ ] 글로벌 CLAUDE.md 길이 110-140줄 (현재 192줄 → 약 30% 감소)
- [ ] Context Block 4-블록 (Who/What/Constraints/Good outcome) 모두 명시
- [ ] Problem-first workflow 6단계 + "분해는 너비, E2E는 깊이" 명제 명시
- [ ] Skill+model sub-agent 규약 명시
- [ ] 결정적 규약(Tools/Paths/Git) 보존 — 회귀 없음
- [ ] `<when-creating-obsidian-document>` `<when-java-project>` 글로벌에서 제거
- [ ] `obsidian-document-workflow` skill 생성 + description-based 트리거 작동
- [ ] `java-structural-ops` skill 생성 + description-based 트리거 작동
- [ ] Vault CLAUDE.md 본문 변경 없음
- [ ] Sonnet 4.6 호환성 유지 (모델 라우팅 후 동일 가이드 유효)

## Open Questions / Future Work

- "Who I work with" 항목은 사용자가 수동 보완 (HTML 코멘트로 가이드 제공)
- skill description의 트리거 키워드 정확도는 1주 운영 후 조정 가능
- Sonnet 4.6 전용 미세 조정이 필요하면 `<when-sonnet-4-6>` 같은 conditional tag 신설 검토 (현재 Out of Scope)

## References

- vault: `003-RESOURCES/AI/CLAUDE-CODE/opus-4-7-differeces.md`
- vault: `003-RESOURCES/AI/CLAUDE-CODE/Pawel-Huryn-Opus47-프롬프팅-전략-변화.md`
- vault: `003-RESOURCES/AI/CLAUDE-CODE/Claude-Code-Opus-4.7-Best-Practices.md`
- vault: `003-RESOURCES/AI/CLAUDE-CODE/Claude-Opus-4.7-리터럴-해석과-프롬프트-엔지니어링-변화.md`
- 현재 CLAUDE.md: `~/.claude/CLAUDE.md` (192줄)
- Vault CLAUDE.md: `~/DocumentsLocal/msbaek_vault/CLAUDE.md`
- 기존 spec 사례: `docs/superpowers/specs/2026-04-29-skill-mcp-cleanup-design.md`
