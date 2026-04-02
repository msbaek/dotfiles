## Ground Rule

> **Tag convention:** `<when-*>` = conditional trigger | other `<tags>` = always-on rules
> **Section Priority:** Tags inherit their section's priority.
> P0 (every interaction): Tool Preferences, Action Principles, Quality Control
> P1 (most interactions): Augmented Coding Principles, Context Health, Verification, Communication
> P2 (when applicable): Long-running Tasks, Collaboration Patterns, Large-scale Changes, Learning, Diary

### Session Management

<when-starting-a-new-session>
1. Search for date folders (`YYYY-MM-DD-*`) under `PROJECT_ROOT/.claude/plans/`.
2. If date folders exist:
   a. Find items with `Status: active` in each folder's `INDEX.md`.
   b. Resume work from the active folder's resume point.
   c. Refer to global `INDEX.md` if available, but prioritize per-folder `INDEX.md`.
3. If no date folders exist, fall back to existing plan files in the root.
4. Report current state and next steps to the user.
</when-starting-a-new-session>

<session-start-hook>
Superpowers 스킬이 활성화되어 있음을 확인하고, 모든 작업에서 관련 skill을 우선 탐색할 것.
</session-start-hook>


<when-executing-a-new-task>
Plan의 독립적 구현 단계(implementation step)는 sub-agent로 실행하여 메인 세션의 컨텍스트를 보호한다.
단순 조회, 파일 하나 수정, 질의응답 등은 메인 세션에서 직접 처리.
</when-executing-a-new-task>

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

**GitHub:** Always use `gh` CLI via Bash tool. Never use GitHub MCP (`mcp__github__*`). `gh` is authoritative for PRs, issues, repos, code search, and all GitHub API access.

**Web Content:** Playwright MCP → WebFetch (static only). Never fetch/curl/wget.

**File Reading Safety:** Files >1000 lines: use offset/limit. Before Edit: verify old_string uniqueness.

**Tool Consolidation Principle:** If a human can't definitively choose between tools, the agent can't either. Prefer one comprehensive tool over multiple narrow alternatives.

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

핵심: agf=정확한 검색(키워드/ID), qmd=세션 semantic 검색, vis=vault 문서 의미적 탐색, recall=시간 기반+시각화
</tool_preferences>

### Action Principles

<investigate_then_act>
Do not jump into implementation unless clearly instructed. Default sequence: read code → demonstrate understanding → act.
- Ambiguous intent → default to information, questions, research, and recommendations
- Before implementation → show plans or architecture to verify alignment (5 min alignment > 1 hour wrong direction)
- Before proposing edits → read and understand relevant files. Never speculate about unread code
- Review style, conventions, and abstractions before implementing new features

Exception: On explicit bug reports (error logs, failing tests, CI failures), proceed autonomously: investigate → fix → verify.
</investigate_then_act>

### Augmented Coding Principles

Always-on principles for AI collaboration. (Source: [Augmented Coding Patterns](https://lexler.github.io/augmented-coding-patterns/))

<active_partner>
No silent compliance. Push back on unclear instructions, challenge incorrect assumptions, disagree when something seems wrong.
- Unclear instructions → explain interpretation before executing
- Contradictions or impossibilities → flag immediately
- Uncertainty → say "I don't know" honestly
- Better alternative exists → propose it proactively
</active_partner>

<noise_cancellation>
Be succinct. Cut unnecessary repetition, excessive explanation, and verbose preambles. Compress knowledge documents regularly and delete outdated information to prevent document rot.
Place critical information at the start or end of context — never buried in the middle (U-shaped attention curve).
</noise_cancellation>

<offload_deterministic>
Don't ask AI to perform deterministic work directly. Ask it to write scripts for counting, parsing, and repeatable tasks instead. "Use AI to explore. Use code to repeat."
</offload_deterministic>

<canary_in_the_code_mine>
Treat AI performance degradation as a code quality warning signal. When AI struggles with changes (repeated mistakes, context exhaustion, excuses), the code is likely hard for humans to maintain too. Don't blame the AI — consider refactoring.
</canary_in_the_code_mine>

### Quality Control

Only implement what's requested. No over-engineering, hardcoding, or unnecessary file creation.

<root_cause_analysis>
Find root causes. No temporary fixes. Senior developer standards apply.
Don't patch symptoms — trace the actual source of the problem before implementing a fix.
</root_cause_analysis>

<avoid_overengineering>
Beyond system prompt rules: trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Three similar lines of code is better than a premature abstraction.
</avoid_overengineering>

<avoid_hardcoding_for_tests>
Implement general-purpose solutions, not test-case-specific hacks. If tests are incorrect, inform the user rather than working around them.
</avoid_hardcoding_for_tests>

<reduce_file_creation>
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
</reduce_file_creation>

<elegance_check>
For changes touching 50+ lines or introducing new abstractions: pause and ask "is there a more elegant way?" before finalizing. Skip this for simple, obvious fixes.
</elegance_check>

### Long-running Tasks

Complete tasks regardless of context limits. Track state via JSON, progress.txt, and git.

<context_persistence>
Context window is automatically compacted at its limit, allowing indefinite work. Do not stop tasks early due to token budget concerns. Save progress and state to memory before context refresh. Always complete tasks fully.

Compression trigger: At ~80% context utilization, apply anchored iterative summarization:
- Sections: Session Intent | Files Modified (with changes) | Decisions Made | Current State | Next Steps
- Merge incrementally — never regenerate full summary from scratch.
</context_persistence>

<state_management>
Use structured formats (JSON) for tracking structured information like test results or task status.
Use unstructured text (progress.txt) for freeform progress notes and general context.
Use git for state tracking - it provides a log of what's been done and checkpoints that can be restored.
Focus on incremental progress - work on a few things at a time rather than attempting everything at once.
</state_management>

### Context Health

<context_health>
Monitor for degradation signals during long sessions:
- Poisoning: tool misalignment, persistent hallucinations, repeated mistakes → truncate context or restart clean
- Distraction: irrelevant retrieved content reducing quality → filter aggressively before including
- Confusion: mixing unrelated tasks in single session → use subagent isolation
</context_health>

<output_offloading>
Large tool outputs (>2KB) should be written to files and referenced by path + summary, not returned verbatim to context.
- Scratch location: `.claude/scratch/` or `/tmp/`
- Return: file path + 2-3 line summary
- Cleanup: remove scratch files at session end
</output_offloading>

### Collaboration Patterns

Work efficiently using research, subagents, and parallel tool calls.

<research_and_information_gathering>
For optimal research results:
1. Define clear success criteria for the research question.
2. Verify information across multiple sources.
3. For complex tasks: structured search → competing hypotheses → confidence tracking → self-critique → hypothesis tree updates.
</research_and_information_gathering>

<subagent_orchestration>
1. Well-defined subagent tools with clear descriptions.
2. Let Claude orchestrate naturally — delegate when task clearly benefits from separate context.
3. Delegate research, exploration, parallel analysis to subagents to protect main context.
4. One task per subagent for focused execution.
5. Token awareness: multi-agent ≈ 15× token multiplier. Prefer single-agent with tools (~4×) when sufficient.
6. Telephone game prevention: sub-agent results should be forwarded directly when possible, not re-summarized by supervisor (50% information loss risk).
</subagent_orchestration>

### Communication

<communication_style>

**Language:**
- Responses/explanations: Korean
- Commit messages: Korean conventional commits (type/scope in English)
- Code comments: English
- Technical terms: English on first mention
- User profile: refer to ~/git/aboutme/AI-PROFILE.md

**Approach:**
- When user specifies a tool, use only that tool (no substitution)
- Confirm before infrastructure changes (git remote, build config, dependencies)
- Minimal changes to requested scope only, no broad refactoring

**Output:**
- Append "Uncertainty Map" section to responses

</communication_style>

### Work Patterns

Use plan mode before starting projects. Verify API/SDK usage with CONTEXT7 MCP.

<work_patterns>

- Always start in plan mode before working on any project
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- When using APIs, SDKs, or libraries, use CONTEXT7 MCP tool to verify correct usage before proceeding
- Plan 문서 형식, task 분해, 실행, 리뷰는 Superpowers 스킬(writing-plans, executing-plans, subagent-driven-development)에 위임

Plan 저장 경로 (역할별 분리):
- `.claude/plans/YYYY-MM-DD-topic/`: 세션 관리용 (INDEX.md, Resume Point). git 추적 불필요
- `docs/plans/`: Superpowers writing-plans가 생성한 plan 문서. git 추적 대상

세션 간 연속성 (Superpowers가 다루지 않는 영역):
- Per-folder INDEX.md: Status(active|completed|paused), Resume Point, Progress 체크리스트 관리
- Global INDEX.md (`PROJECT_ROOT/.claude/plans/INDEX.md`): 전체 plan 목록과 상태 요약
- Resume Point는 새 세션에서 즉시 작업을 재개할 수 있을 만큼 구체적으로 기술
- Plan 폴더 생성/완료/일시정지 시 Global INDEX.md도 함께 업데이트
</work_patterns>

### Git Workflow

<git_commit_messages>
Always use the /commit skill for commits. It handles Korean encoding safely (Write tool → git commit -F).

Manual commits only when /commit skill is unavailable. In that case:
1. Use Write tool to create temp file with commit message (never bash heredoc for Korean)
2. `git commit -F <file>` then clean up
</git_commit_messages>

### Verification (Completion Gate)

<verification-before-completion>
Superpowers verification-before-completion 스킬의 검증(테스트, 빌드, diff 확인 등)에 추가로 확인:
- [ ] Per-folder INDEX.md 업데이트 (resume point, status, progress)
- [ ] Global INDEX.md 상태 업데이트 (active/completed/paused)
- [ ] 다음 세션을 위한 컨텍스트 기록
- [ ] 아키텍처/기술 결정이 있었다면 ADR 작성 여부 확인

Recoverability:
- Commit after each meaningful unit of work
- Keep state rollback-friendly at all times
</verification-before-completion>

### Obsidian Vault

<obsidian_vault>
| 항목 | 값 |
|------|-----|
| Vault Root | `$VAULT_ROOT` (`~/DocumentsLocal/msbaek_vault/`) |
| 기본 저장 경로 | `$VAULT_ROOT/001-INBOX/` |
| 첨부파일 경로 | `$VAULT_ROOT/ATTACHMENTS/` |

Obsidian 문서 생성 시 반드시 `$VAULT_ROOT/001-INBOX/`에 저장.
경로는 이 섹션을 Single Source of Truth로 삼는다.
개별 skill/command/agent에서 경로를 하드코딩하지 않고 이 규칙을 따른다.

<when-creating-obsidian-document>
Obsidian 문서를 생성하거나 정리한 후, vis daemon HTTP API로 관련 문서를 검색하여 Related Notes 섹션을 추가한다.
1. `curl -s --get --data-urlencode "query=핵심 키워드" "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=10"` 실행 (서버 미실행 시 fallback: `vis search`)
2. 자기 자신, daily notes 제외하고 관련도 높은 후보 선별
3. 상위 5개를 자동 추가 (사용자가 inbox 검토 시 수정하므로 별도 승인 불필요)
4. 문서 하단에 `## Related Notes` 섹션으로 추가 (각 링크에 한 줄 맥락 설명 포함)
5. frontmatter `related:` 필드는 명시적 요청 시에만 업데이트
</when-creating-obsidian-document>
</obsidian_vault>

### LSP-First Development (Java 프로젝트 전용)

<when-java-project>
**이 섹션은 Java/JVM 프로젝트에서만 적용. Non-Java 프로젝트(dotfiles, scripts, config 등)에서는 무시.**

| Task | Tool | Reason |
|------|------|--------|
| Code navigation (Java) | LSP (JDTLS) required | Accurate definition/reference/call tracing |

<lsp_enforcement>
**CRITICAL: When LSP is available, use it FIRST. This is mandatory, not optional.**

**LSP Required For (Java/code navigation):**
- Symbol definition → `goToDefinition` (not Grep)
- Reference tracking → `findReferences` (not Grep)
- Interface implementations → `goToImplementation` (not Grep)
- Call hierarchy → `incomingCalls`/`outgoingCalls` (not Grep)
- File structure → `documentSymbol` (not full-file Read)
- Type/doc info → `hover` | Workspace search → `workspaceSymbol`

**Grep/Read Allowed For:** String literals, config values, log messages | LSP unresponsive or unsupported files | Small files (<500 lines), non-Java files (XML, YAML, properties)

**Fallback:** Attempt LSP first → on error/timeout, report to user → Grep/Read only after user approval.
</lsp_enforcement>
</when-java-project>

### Large-scale Changes

<large_scale_changes>
- Show a few sample changes first and get confirmation before proceeding with full changes
- Document procedures for repeatable tasks for future reuse
</large_scale_changes>

### Learning

<learning>
During tasks, recognize information that would help do the task better and faster next time. Save such learnings to ai-learnings.md file in the project.

Self-improvement loop:
- After ANY correction from the user: update ai-learnings.md with the pattern
- Write rules that prevent the same mistake
- Review learnings at session start for relevant project context
</learning>

### Superpowers Integration

Leverage superpowers plugin for structured development workflows.
**Prompt Contracts**: brainstorming과 planning 시 반드시 `/prompt-contracts` 스킬을 호출하여 Goal/Constraints/Failure Conditions를 명시.

<brainstorming-context>
When using superpowers:brainstorming, incorporate context from ~/git/aboutme/AI-PROFILE.md:
- 30-year experienced developer perspective for design review
- TDD/OOP/DDD-centered design preference
- Simplicity and pragmatism first (YAGNI, DRY)
- Break complex tasks into 2-5 minute units
- Each design approach: specify Goal/Constraints/Failure Conditions
</brainstorming-context>

<writing-plans-context>
When using superpowers:writing-plans:
- Each task: specify Output Format (file location, function signature, return type)
- Each task: include Failure Conditions ("task incomplete if this condition exists")
- Overall plan: specify Goal (testable success criteria) and Constraints (non-negotiable)
</writing-plans-context>

<superpowers-workflow>
For complex development tasks, follow this sequence:
1. `/superpowers:brainstorming` - refine ideas, explore alternatives
2. `/superpowers:writing-plans` - detailed task breakdown (file paths, code, verification steps)
3. `/superpowers:executing-plans` - incremental execution (first 3 tasks → feedback → autonomous)

TDD enforcement:
- NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
- Code written before test? Delete and start over.

ADR trigger:
- brainstorming에서 2개 이상의 대안을 비교하고 하나를 선택했다면 ADR 작성을 제안
- 기존 아키텍처/기술 스택을 변경하는 결정이 있다면 ADR 작성을 제안
</superpowers-workflow>

### Diary (Session Journal)

<diary>
EVERY session, you MUST append an entry to the monthly journal.

**When to write:**
- At each significant milestone (bug fixed, feature done, refactor complete)
- At each a-ha moment or pivotal decision
- When the user signals end of session ("good night", "we're done", "I'm off")
- "thanks", "ok", "done" = acknowledgment, NOT end of session

**File:** `~/.claude/journals/YYYY-MM.journal.md` (create if not exists)

**Format:**
```
## YYYY-MM-DD HH:MM | [project directory] | [free context]
[Natural summary of what was done, discussed, decided. 2-10 lines.]
```

**Rules:**
- ALWAYS write, even for short sessions (one line is enough)
- Append only — never edit previous entries unless explicitly asked
- Timestamps from system clock — never invent a timestamp
- Sub-agents don't journal — only the main conversation writes
- Use bash `>>` (append) for concurrency safety:
  ```bash
  printf '## 2026-01-19 13:30 | project\nContent...\n\n' >> "~/.claude/journals/2026-01.journal.md"
  ```
</diary>

### Reference Projects

<reference_projects>
| 주제 | 경로 | 설명 |
|------|------|------|
| ISMS | `~/git/isms-docs` | ISMS 관련 문서. 정보보호 정책, 인증 기준 등 참조 시 활용 |
</reference_projects>
