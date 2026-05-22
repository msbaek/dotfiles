
## Session lifecycle (when-\* hooks)

<when-starting-a-new-session>
1. `PROJECT_ROOT/.claude/plans/`에서 `YYYY-MM-DD-*` 폴더 중 INDEX.md `Status: active` 확인
2. Active 폴더 resume point에서 재개 (없으면 root plan 파일로 fallback)
3. 현재 상태와 다음 단계 보고
</when-starting-a-new-session>

<session-start-hook>Superpowers 스킬이 활성화되어 있음을 확인하고, 모든 작업에서 관련 skill을 우선 탐색할 것.</session-start-hook>

<when-plan-complete>
**트리거 조건** (어느 하나라도 true → 즉시 발화):
1. `ExitPlanMode` 호출 직후 첫 응답
2. plan 파일(`.claude/plans/*.md` 또는 `docs/superpowers/plans/*.md`) 작성·갱신 직후 다음 turn
3. 사용자 입력에 다음 키워드 포함: "구현해줘", "코드 작성", "commit해", "test 돌려", "PR 만들어", "push해", "배포"
4. TodoWrite로 task list 만든 직후 첫 Edit/Write/Bash 호출 turn
5. `/commit`·`/wrap-up`·`/session-handoff`·`/skills-audit` 등 기계적 실행 skill 호출

**발화 워딩** (정확히 이대로):
> 계획 단계 완료. 이제부터 기계적 실행 단계입니다.
> `/model claude-sonnet-4-6` 전환을 권장합니다.
> (Opus 유지 원하시면 "opus 유지"라고 답해주세요 — 같은 세션에서 재안내 안 함)

**Skip 조건**:
- 현재 모델이 이미 `claude-sonnet-*` 계열
- 같은 세션에서 stickiness state file(`/tmp/claude-model-decision-${session_id}.json`)에 `keep_opus: true` 기록됨 — 또는 직전 turn에 사용자가 "opus 유지"·"그대로"·"바꾸지 마" 답변
- `superpowers:brainstorming` skill이 직전 turn에 호출됨 (창의 단계 = Opus 적합)

**Stickiness 리셋 조건** (재안내 허용):
- 다음 skill 호출: `superpowers:brainstorming`, `superpowers:writing-plans`, `ExitPlanMode`
- 새 세션 시작

**Hook 보강**: `skill-model-advisor.py`(PreToolUse)와 `slash-command-model-advisor.py`(UserPromptSubmit) 두 hook이 세션 JSONL(`~/.claude/projects/*/<session_id>.jsonl`)에서 현재 모델을 직접 식별한다. 이미 타겟 family면 hook이 침묵하므로, **hook 출력이 나오면 무조건 추정 없이 사용자에게 그대로 안내**할 것 (모델 자기 인식 실패로 self-skip 금지). 2·3·4번 트리거는 hook 미커버 영역 → 본 규칙에 따라 직접 안내. stickiness는 UserPromptSubmit hook이 pending-marker gate로 자동 관리.
</when-plan-complete>

<when-completing-task>
완료 전: per-folder INDEX.md + Global INDEX.md 갱신, 다음 세션용 context 기록, 아키텍처 결정 시 ADR 제안. 의미 단위마다 commit하여 rollback-friendly 상태 유지. (superpowers `verification-before-completion` 미트리거 시의 보호망)
</when-completing-task>

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
