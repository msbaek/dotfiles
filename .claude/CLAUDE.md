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

### Backward (A 의 Top 5 각각에 대해 역방향 Related Notes full refresh)

> **설계 의도:** X 자체의 최신 Top 5 로 X 의 Related Notes 를 refresh 한다. A 를 X 에 강제 삽입하지 않음 — A 가 X 의 Top 5 에 포함되면 자연스럽게 반영됨.

**Config (변경 시 이 블록만 수정):**
- `top_k`: 5
- `bootstrap_mode`: `"minimal"` (없는 섹션은 A 링크 1 줄만 신설. `"full"` 로 전환 시 Top 5 전체 신설)
- `exclude_patterns`: `["work-log/*.md", "ATTACHMENTS/**", "<A-path>", "frontmatter.draft == true"]`
- `first_run_policy`: `"sync_dryrun_once"` (`.trusted` 없으면 강제 동기 dry-run)
- `concurrency`: `"sequential"` (active/*.json polling)
- `state_dir`: `~/.claude/state/vis-backlink/`
- `log_path`: `~/.claude/logs/vis-backlink-YYYYMMDD.log` (자동 rollover, append-only)

**사전 가드 (모두 통과해야 backward 진입):**

0. .disabled 마커 체크: `[ -f ~/.claude/state/vis-backlink/.disabled ]` 가 참이면 → `ENV_DISABLED` → backward 스킵, forward 는 유지, 사용자에게 인라인 고지: "ℹ️ backward Related Notes 비활성화 (재활성화: /vis-backlink-toggle on)". `.trusted` 게이트보다 먼저 평가하여 dry-run도 발생하지 않음.
1. git dirty tree 체크: `cd <vault_root> && git status --porcelain` 결과가 비어있지 않으면 `ENV_DIRTY_TREE` → backward 스킵, forward 는 유지, 사용자에게 "vault dirty → backward 생략" 인라인 고지.
2. `state_dir` 부트스트랩: `mkdir -p ~/.claude/state/vis-backlink/{active,history}` (이미 있으면 noop).
3. 동시성 체크: `ls ~/.claude/state/vis-backlink/active/*.json 2>/dev/null` 에 결과가 있으면 2초 주기 polling. 5초 경과 후에도 대기 중이면 "선행 backward job 대기 중" 1회 알림. `phase in {completed, failed, partial_failure}` 가 되면 해제. `phase=crashed` 가 감지되면 → `mv active/<id>.json history/<id>.json` 후 "crashed job 자동 정리" 로그 append 하고 즉시 해제 (blocking 없이 진행).

**분기 (.trusted 마커로 1회 gate):**

- `.trusted` 부재 → 동기 dry-run (Flow 1). 아래 "Dry-run 프로시저" 수행.
- `.trusted` 존재 → 비동기 dispatch (Flow 2). 아래 "Async dispatch 프로시저" 수행.

**Dry-run 프로시저 (Flow 1, 첫 실행 한 번):**

1. vis `/search` 호출: `curl -s --get --data-urlencode "query=<A-title>" "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=5"` (A 의 frontmatter title, 없으면 첫 # 헤딩 텍스트)
2. 응답의 각 후보 X 에 대해 `exclude_patterns` 적용. A 자신은 무조건 제외.
3. 각 X 에 대해 "X 처리 서브루틴" 을 **드라이런 모드** 로 수행 (실제 쓰기 없이 diff 계산).
4. 대화 내 C6 포맷으로 diff 출력:
   ```
   역방향 Related Notes 업데이트 미리보기
   새 문서: A = <A_path>
   역방향 대상 (vis Top 5, 자동 제외 적용 후):
     [1] B = ... (섹션 있음)
     [2] C = ... (섹션 없음 → bootstrap minimal)
     [3] D = ... (제외: work-log/**)
     ...
   실제 수정 대상: B, C
   B 변경안 diff: ...
   [계속 적용 / 취소 / 선택 적용]
   ```
5. 사용자 승인 → MultiEdit 순차 적용 → `touch ~/.claude/state/vis-backlink/.trusted`.
6. 사용자 거부 → 변경 없음, `.trusted` 생성 안 함. 다음 새 문서 생성 시 다시 dry-run.

**Async dispatch 프로시저 (Flow 2, `.trusted` 이후):**

1. `job_id=$(date +%Y%m%d-%H%M%S)-$(basename A .md)` 형태로 생성.
2. `~/.claude/state/vis-backlink/active/<job_id>.json` 에 초기 state 기록 (atomic: tmp → rename):
   ```json
   {"job_id": "...", "source": "<A_path>", "started_at": "<ISO8601>",
    "updated_at": "<ISO8601>", "phase": "dispatched",
    "subagent_name": "vis-backlink-<hash>",
    "progress": {"total": 0, "done": 0, "failed": 0},
    "targets": [],
    "log_path": "~/.claude/logs/vis-backlink-<date>.log"}
   ```
3. Agent 도구로 subagent dispatch:
   - `subagent_type`: `"general-purpose"`
   - `name`: `"vis-backlink-<short-hash>"`
   - `run_in_background`: `true`
   - `prompt`: "X 처리 서브루틴" 섹션 전체 + config + state JSON 경로 + 대상 후보 (Top 5, 제외 적용 후) 를 인용. subagent 는 반드시 (a) atomic state rewrite, (b) C3 파서 규칙, (c) 에러 카탈로그 대응 수행.
4. 메인 Claude 는 즉시 해제. 사용자는 다음 forward 작업 가능. 2초 이내 해제되어야 함 (T3).

**X 처리 서브루틴 (C2, subagent 또는 dry-run 메인이 수행):**

입력: `X_path`. 출력: X 수정 또는 skip 이유 + state update.

1. `Read X_path` → 원본 전체.
2. C3 파서로 섹션 분해: `(before, related_lines, after)`.
   - 섹션 시작: `^## Related Notes\s*$`
   - 섹션 종료: 다음 `^## ` 또는 EOF
   - 각 줄 문법: `^-\s+\[\[(?P<link>[^\]]+)\]\](\s+—\s+(?P<desc>.+))?$`
   - 일탈 줄 (멀티라인 desc, 주석, `![[...]]` 이미지 링크, 확장자 있는 링크): **해당 파일 skip**. state `targets[X].status="skipped_parse"`, 사유 기록.
3. vis `/search` 호출 (`query=<X-title>` — X 의 frontmatter title, 없으면 첫 # 헤딩 텍스트, `top_k=5`, `rerank=true`) → X 의 최신 Top 5. `exclude_patterns` 적용 (X 자신은 무조건 제외).
4. 각 링크 L 에 대해 설명(desc) 결정:
   - L 이 기존 related_lines 에 있음 → 기존 desc 보존
   - L 이 신규 → LLM 생성 (1-2 문장 맥락 설명). 실패 → vis 응답의 snippet fallback, state 에 `llm_desc_fail` 플래그.
5. new_lines 조립 기준:
   - 섹션 **없음** + `minimal` → `[- [[A]] — <A-title>]` 단 1줄 (A 의 frontmatter title, 없으면 첫 # 헤딩. A 는 step 3 쿼리 기준 X 검색 결과에 포함 여부 무관하게 삽입)
   - 섹션 **없음** + `full` → step 4 결과 Top 5 전체
   - 섹션 **있음** (minimal/full 무관) → step 4 결과 Top 5 로 full refresh (기존 줄 교체, desc 는 step 4 기준)
6. `assembled = before + "## Related Notes\n\n" + "\n".join(new_lines) + "\n" + after`.
7. `MultiEdit(X_path, old=원본, new=assembled)`.
8. state atomic update: `targets[X].status="done"`, `duration_ms`, `changes={added, preserved, removed}`.

**완료 · 정리:**

- 모든 targets 처리 완료 → state `phase="completed"`, `mv active/<id>.json history/<id>.json`.
- 일부 실패 → `phase="partial_failure"`, active/ 유지.
- `history/` 30개 초과 → 가장 오래된 것 삭제: `ls -t ~/.claude/state/vis-backlink/history/ | tail -n +31 | xargs -I{} rm ~/.claude/state/vis-backlink/history/{}`.
- 로그: `[DONE] <job_id> total=N done=N failed=N skipped=N duration=...s` append.

**에러 카탈로그 (spec §8 E1 요약, subagent 는 엄격 준수):**

| 코드 | 감지 | 처리 |
|---|---|---|
| `ENV_DISABLED` | `.disabled` 마커 | backward 중단, forward 유지, 인라인 안내 |
| `ENV_DIRTY_TREE` | git status | backward 중단, forward 유지, 인라인 안내 |
| `ENV_VIS_DOWN` | curl timeout 5s | Abort, notification |
| `ENV_NO_TRUSTED` | `.trusted` 부재 | 동기 dry-run 진입 |
| `DATA_PARSE_FAIL` | C3 일탈 | 해당 X skip, 로그 |
| `DATA_FILE_MISSING` | Read 실패 | skip |
| `DATA_SELF_REFERENCE` | filter | 조용히 제외 |
| `LLM_CONTEXT_FULL` | 내부 | Abort, notification |
| `LLM_DESC_GEN_FAIL` | 응답 파싱 | snippet fallback |
| `IO_WRITE_FAIL` | MultiEdit | skip, notification |
| `CONCURRENT_DISPATCH` | active/ 존재 | polling |
| `SUBAGENT_CRASH` | Claude Code | phase=crashed, 수동 정리 힌트 (`/vis-backlink-status --clear-failed` 안내, 인라인 알림 즉시 출력) |

**상태 조회:** `/vis-backlink-status` 스킬 사용 (별도 파일).
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
