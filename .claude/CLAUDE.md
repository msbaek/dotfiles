## Ground Rule

> **Tag:** `<when-*>` = conditional | other `<tags>` = always-on
> P0: Tool Preferences, Action Principles, Quality Control
> P1: Augmented Coding, Context Health, Verification, Communication
> P2: Long-running Tasks, Collaboration, Large-scale Changes, Learning, Diary

### Session Management

<when-starting-a-new-session>
1. Check `PROJECT_ROOT/.claude/plans/` for `YYYY-MM-DD-*` folders with `Status: active` in INDEX.md.
2. Resume from active folder's resume point (or fall back to root plan files).
3. Report current state and next steps.
</when-starting-a-new-session>

<session-start-hook>Superpowers 스킬이 활성화되어 있음을 확인하고, 모든 작업에서 관련 skill을 우선 탐색할 것.</session-start-hook>
<when-executing-a-new-task>독립 구현 단계 → sub-agent(컨텍스트 보호). 단순 조회/수정/Q&A → 메인 세션.</when-executing-a-new-task>

### Tool Preferences

<tool_preferences>
| Task | Tool | Reason |
|------|------|--------|
| Syntax-aware search | `sg --lang <lang> -p '<pattern>'` | Structural matching |
| Text search | `rg` (ripgrep) | Fast, respects .gitignore |
| File finding | `fd` | Fast, intuitive |
| Web content | Playwright MCP first | Dynamic/auth content, Cloudflare bypass |
| Large files (>500 lines) | Serena/LSP symbolic tools | More efficient than Read |
| GitHub operations | `gh` CLI (Bash tool) | Reliable, auth built-in |

**GitHub:** `gh` CLI only (never `mcp__github__*`). **Web:** Playwright MCP → WebFetch. Never fetch/curl/wget.
**Files >1000 lines:** use offset/limit. Before Edit: verify old_string uniqueness.

**Claude 세션 검색:**

| 상황 | 도구 | 예시 |
|------|------|------|
| 날짜별 세션 목록 | `/agf list` | `/agf list 2026-03-07` |
| 세션 상세 + AI 요약 | `/agf show` | `/agf show a1b2c3d4` |
| 키워드로 세션 제목 검색 | `/agf search` | `/agf search dotfiles` |
| 세션 대화 내용까지 검색 | `/agf search --deep` | `/agf search --deep "vis 설치"` |
| 세션 semantic 검색 | `qmd` | `qmd "TDD 리팩토링"` |
| Vault 문서 의미적 탐색 | `vis search` | `vis search "TDD 리팩토링" --rerank` |
| 시간 기반 타임라인 | `/recall` | `/recall last week` |
| 세션-파일 관계 그래프 | `/recall graph` | `/recall graph last week` |

agf=정확한 검색(키워드/ID), qmd=세션 semantic 검색, vis=vault 문서 의미적 탐색, recall=시간 기반+시각화
</tool_preferences>

### 모델 라우팅 (Max plan Opus quota 관리)

- 결정적 검증 필요 시: `@advisor` 호출
- 단순 탐색·파일 읽기: `@explorer` (Haiku)
- Opus 주간 quota 50% 도달 시: `/model claude-sonnet-4-6`으로 전환
- Fast mode는 **절대** 쓰지 말 것 (extra-usage billing, Max plan 미포함)

<when-plan-complete>계획/설계/advisor 상담이 끝나고 구현·커밋·테스트·문서 업데이트 같은 기계적 작업으로 넘어가는 전환 지점에서 `/model claude-sonnet-4-6` 전환을 능동적으로 제안할 것. hook `~/.claude/hooks/skill-model-advisor.py`가 `ExitPlanMode`와 writing-plans/executing-plans/subagent-driven-development skills만 자동 커버하므로, 그 밖의 경로(일반 대화로 계획이 완성된 경우 등)는 어시스턴트가 직접 안내해야 함. 사용자가 Opus 유지 결정하면 재제안 금지.</when-plan-complete>

### Action Principles

<investigate_then_act>
Default: read → understand → act. Never speculate about unread code.
- Ambiguous → information/questions/recommendations first
- Before implementation → show plan to verify alignment
- Exception: explicit bug reports → investigate → fix → verify autonomously
</investigate_then_act>

### Augmented Coding Principles

<active_partner>Push back on unclear/wrong instructions. Flag contradictions immediately. Say "I don't know" honestly. Propose better alternatives proactively.</active_partner>

<noise_cancellation>Be succinct. Critical info at start/end (U-shaped attention). Compress knowledge docs, delete outdated info.</noise_cancellation>

### Quality Control

Only implement what's requested.

- Root cause: trace actual source, no temp fixes
- No overengineering: trust internal code; validate at system boundaries only
- No test hacks: general solutions; if tests are wrong, inform user
- Cleanup: remove temp files after task
- Elegance check (50+ line changes): "is there a simpler way?"

### Long-running Tasks

Context auto-compacts — don't stop early. At ~80%: summarize (Intent | Files Modified | Decisions | State | Next Steps), merge incrementally.
State: JSON=structured, progress.txt=freeform, git=checkpoints. Incremental progress.

### Context Health

Signals: Poisoning (hallucinations, repeated mistakes) → restart | Distraction (irrelevant content) → filter | Confusion (mixed tasks) → subagent isolation.
Large outputs (>2KB): write to `.claude/scratch/` or `/tmp/`, return path + summary, cleanup at end.

### Collaboration Patterns

<subagent_orchestration>
Delegate research, exploration, parallel analysis. One task per subagent. Multi-agent ≈ 15× tokens; prefer single-agent (~4×) when sufficient. Forward results directly — don't re-summarize (50% info loss).
</subagent_orchestration>

### Communication

**Language:** Responses=Korean | Commits=Korean conventional commits | Code comments=English | Technical terms=English first | Profile: `~/git/aboutme/AI-PROFILE.md`
**Rules:** Use only user-specified tools | Confirm before infra changes | Minimal scope | Append "Uncertainty Map"

### Work Patterns

- 작업 규모별 계획 시스템 선택 — Plan Mode와 writing-plans 동시 사용 금지 (같은 게이트):
  - 단순(버그픽스 등): 직접 실행
  - 중간(기존 기능 수정): Plan Mode만
  - 복잡(신규 기능, 대규모 리팩토링): brainstorming → writing-plans → executing-plans (Plan Mode 생략)
- STOP and re-plan if sideways. CONTEXT7 MCP for APIs/SDKs.
- Paths: `docs/superpowers/plans/` (writing-plans 출력, git 추적) | `.claude/plans/YYYY-MM-DD-topic/` (세션 상태 포인터, 내용 복제 금지)
- INDEX.md Resume Point: writing-plans 문서의 다음 Task 위치 직접 참조
- INDEX.md: per-folder (Status/Resume Point/Progress) + Global. Update both on create/complete/pause.
- Large-scale: show sample first, confirm before full rollout

### Git Workflow

<git_commit_messages>
Always use `/commit` skill (Write tool → git commit -F, Korean-safe).
Manual fallback: Write temp file → `git commit -F <file>` → delete. Never bash heredoc for Korean.
</git_commit_messages>

### Verification (Completion Gate)

Before completing:
- [ ] Per-folder INDEX.md updated (resume point, status, progress)
- [ ] Global INDEX.md updated (active/completed/paused)
- [ ] Context recorded for next session
- [ ] Architecture decisions → suggest ADR
Recoverability: commit after each meaningful unit; keep state rollback-friendly.

### Obsidian Vault

Vault: `~/DocumentsLocal/msbaek_vault/` | Save: `001-INBOX/` | Attachments: `ATTACHMENTS/`

<when-creating-obsidian-document>
Obsidian 문서 A 를 생성하거나 정리한 후 수행한다. forward 는 기존과 동일, backward 는 신규.

### Forward (A 자체에 Related Notes 추가)

1. `curl -s --get --data-urlencode "query=<A-title>" "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=10"` 실행 (A 의 frontmatter title, 없으면 첫 # 헤딩 텍스트. 서버 미실행 시 fallback: `vis search`)
2. 자기 자신, daily notes 제외하고 관련도 높은 후보 선별
3. 상위 5개를 자동 추가 (사용자가 inbox 검토 시 수정하므로 별도 승인 불필요)
4. 문서 하단에 `## Related Notes` 섹션으로 추가 (각 링크에 한 줄 맥락 설명 포함)
5. frontmatter `related:` 필드는 명시적 요청 시에만 업데이트

**Backward Related Notes**: 이제 `/obsidian:add-tag` 또는 `/obsidian:add-tag-and-move-file` 의 마지막 단계에서 `vis-backlink-trigger` 스킬이 처리합니다. 자세한 동작은 `~/git/vault-intelligence/docs/superpowers/specs/2026-04-26-vis-backlink-smart-trigger-design.md` 참조.
</when-creating-obsidian-document>

### LSP-First Development (Java 프로젝트 전용)

<when-java-project>
Java only. LSP (JDTLS) for all navigation: goToDefinition, findReferences, goToImplementation, incomingCalls/outgoingCalls, documentSymbol, hover, workspaceSymbol.
Grep allowed: string literals, config, logs, small files (<500 lines), non-Java. Fallback: report error → Grep with user approval.
</when-java-project>

### Learning

Save non-obvious patterns to `ai-learnings.md` in project. After corrections: update immediately to prevent recurrence.

### Superpowers Integration

`/prompt-contracts` 필수 (brainstorming/planning 시 Goal/Constraints/Failure Conditions 명시).

<brainstorming-context>
~/git/aboutme/AI-PROFILE.md 참조. Each design: specify Goal/Constraints/Failure Conditions.
</brainstorming-context>

<writing-plans-context>
Each task: Output Format + Failure Conditions. Plan: Goal (testable) + Constraints (non-negotiable).
</writing-plans-context>

<superpowers-workflow>
Complex tasks: brainstorming → writing-plans → executing-plans (first 3 → feedback → autonomous)
TDD: NO PRODUCTION CODE WITHOUT FAILING TEST FIRST. ADR: 2+ alternatives → suggest ADR.
showClearContextOnPlanAccept 대응: writing-plans 완료 후 /clear → 실행 단계 진입. subagent-driven-development 사용 시 각 Task가 자동으로 fresh context에서 실행되므로 /clear 불필요.
Plugin 파일 수정 금지: ~/.claude/plugins/ 직접 편집 금지. 커스터마이징은 이 파일의 context 태그(<*-context>)로만.
</superpowers-workflow>

### Diary (Session Journal)

<diary>
EVERY session: append to `~/.claude/journals/YYYY-MM.journal.md`.
Format: `## YYYY-MM-DD HH:MM | [project] | [context]\n[2-10 lines]`
Triggers: milestone, a-ha moment, end signal ("good night", "done", "I'm off"). NOT: "thanks", "ok".
Rules: append-only, system clock only, sub-agents don't journal. Use `printf '...\n\n' >>` for safety.
</diary>

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
