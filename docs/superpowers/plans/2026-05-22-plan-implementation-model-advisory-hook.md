# Plan: plan 구현 진입 시 모델 전환 advisory hook 패치

작성일: 2026-05-22
대상 repo: `~/dotfiles` (`~/.claude` → `~/dotfiles/.claude` 심링크)

---

## 1. 문제 정의

`<when-plan-complete>` 규칙(트리거 1 — "ExitPlanMode 호출 직후 첫 응답")이
**plan 승인 후 구현 단계에서 반복적으로 누락**된다. 모델 전환 권장 발화 없이
곧장 실행에 진입한다.

### 왜 발생하는가 (검증된 원인)

조사 결과 — `skill-model-advisor.py`는 `settings.json`의 `PreToolUse` matcher
`Skill|ExitPlanMode`에 **이미 등록**돼 있고, `lookup()`이 `ExitPlanMode` →
`claude-sonnet-4-6`를 반환한다. 즉 hook 자체는 정상 동작한다.

진짜 gap은 **컨텍스트 경계**다:

1. `ExitPlanMode` 호출 → `PreToolUse` hook 발동 → advisory `additionalContext`가
   **plan 작성 컨텍스트**에 주입됨.
2. 사용자가 plan 승인 → 구현은 **새 컨텍스트**에서 harness 생성 메시지
   `"Implement the following plan:\n\n<plan 본문>"` 으로 시작.
3. `PreToolUse` hook이 주입한 `additionalContext`는 plan 작성 컨텍스트에만
   존재하며 **새 구현 컨텍스트로 넘어오지 않는다**.
4. 새 컨텍스트의 `"Implement the following plan:"`은 slash command가 아니므로
   `slash-command-model-advisor.py`(UserPromptSubmit)가 무시한다.
5. → **구현 컨텍스트 첫 turn에 어떤 hook도 발동하지 않음**. 모델 전환 안내는
   CLAUDE.md 규칙의 자기회상에만 의존하게 되고, 실행 momentum 때문에 실패한다.

### 검증된 사실

| # | 사실 | 근거 |
|---|---|---|
| 1 | `skill-model-advisor.py`는 `ExitPlanMode`에 PreToolUse로 등록됨 | `settings.json` matcher `Skill\|ExitPlanMode` |
| 2 | 동 hook `lookup()`이 `ExitPlanMode` → `claude-sonnet-4-6` 반환 | hook L153-154 |
| 3 | plan 승인 후 구현은 새 컨텍스트 (별도 transcript) | 시스템 노트가 별도 `*.jsonl` 경로 안내 |
| 4 | 구현 컨텍스트 첫 메시지 = `"Implement the following plan:"` prefix | 이 작업 진입 메시지 실측 |
| 5 | `slash-command-model-advisor.py`의 `extract_slash_commands()`는 `^\s*/cmd`만 매칭 | hook L110 |

---

## 2. 승인 조건 (Acceptance Criteria)

- AC1: 구현 컨텍스트 첫 turn(`"Implement the following plan:"`)에서
  UserPromptSubmit hook이 발동해 `additionalContext`로 모델 전환 advisory를 주입한다.
- AC2: 현재 세션 모델이 이미 `claude-sonnet-*` 계열이면 침묵한다 (기존 JSONL gate 재사용).
- AC3: 세션 stickiness(`keep_opus: true`)가 설정돼 있으면 침묵한다 (기존 gate 재사용).
- AC4: 기존 slash command 감지(`EXEC_COMMANDS`)·stickiness 동작은 회귀 없이 유지된다.
- AC5: false positive 시(사용자가 우연히 동일 문구 입력) Sonnet 권장이 출력될 뿐
  무해하다 — 차단(block) 아님, 권장(recommend)만.

## 3. 제약 (Constraints, non-negotiable)

- C1: `skill-model-advisor.py`는 **수정하지 않는다**. UserPromptSubmit hook
  단일 파일(`slash-command-model-advisor.py`)만 패치.
- C2: `settings.json` 미수정 — 해당 hook은 이미 UserPromptSubmit에 등록됨.
- C3: 기존 fail-open 원칙 유지 — JSONL read 실패 시 advisory 발동.
- C4: dotfiles repo 추적 파일 → 모든 단계 `git revert`로 가역.
- C5: 사전커밋 hook `update-brewfile`이 `Brewfile` 수정 가능 → 실패 시 재스테이지 후 재커밋.

## 4. 실패 조건 (Failure Conditions)

- harness 생성 메시지 prefix가 `"Implement the following plan:"`이 아닌
  다른 문구일 경우 감지 실패 → Step 4 검증 게이트에서 적발.
- prompt 본문(plan 전문)에 `/commit` 등 slash 패턴이 있어도 `extract_slash_commands()`는
  `^` 앵커라 오탐 안 함 — 신규 함수도 prefix 앵커 사용으로 동일 보장.

---

## 5. 패치 설계

대상: `~/.claude/hooks/slash-command-model-advisor.py`
(실파일: `~/dotfiles/.claude/hooks/slash-command-model-advisor.py`)

### 5-1. 신규 함수 추가

```python
# plan 승인 후 구현 컨텍스트 진입 시 harness가 생성하는 메시지의 prefix.
# 앵커(^)로 prompt 맨 앞만 매칭 → plan 본문 내 동일 문구 오탐 방지.
PLAN_IMPL_PATTERN = re.compile(r"\s*Implement the following plan:", re.IGNORECASE)


def is_plan_implementation(prompt):
    """True iff this prompt is the harness-generated plan-implementation entry."""
    return bool(PLAN_IMPL_PATTERN.match(prompt))
```

### 5-2. `main()` 통합

기존 `exec_hit = commands & EXEC_COMMANDS` 분기를 일반화한다.

- slash command exec-hit **또는** `is_plan_implementation(prompt)` 둘 중 하나면
  advisory 경로로 진입.
- trigger label: slash command면 `/cmd`, plan 구현이면 `plan 구현 진입`.
- 이후 로직(stickiness skip → JSONL family gate → pending marker 기록 →
  `additionalContext` 출력)은 **기존 코드 그대로 재사용**. 분기만 추가.

권장 구현 형태 (의사 diff):

```python
    exec_hit = commands & EXEC_COMMANDS
    plan_impl = is_plan_implementation(prompt)
    if not exec_hit and not plan_impl:
        sys.exit(0)
    ...
    # trigger label 분기
    if exec_hit:
        label = f"/{sorted(exec_hit)[0]}"
    else:
        label = "plan 구현 진입"
```

`additionalContext` 문구도 분기:
- exec_hit: 기존 `"사용자가 실행 계열 slash command ... 호출했다"`.
- plan_impl: `"plan 승인 후 구현 단계에 진입했다. <when-plan-complete> 트리거 1에
  해당한다. /model claude-sonnet-4-6 전환을 권장하라. 이 안내문을 그대로 출력한 후
  본문을 진행하라. hook이 JSONL에서 현재 모델을 확인했으므로 self-skip 금지.
  사용자가 'opus 유지' 답변 시 같은 세션에서 재안내 금지."`

### 5-3. 영향 없음 확인

- stickiness 분기 (a): pending marker 존재 시에만 동작 → 무관.
- `RESET_COMMANDS` 분기: slash command만 → 무관.
- 새 세션에서 plan 구현 시작 시 `keep_opus` state file은 세션별이라 자연히
  존재하지 않음 → AC3는 동일 세션 구현 시에만 의미. 그대로 둠.

---

## 6. 가역적 실행 단계 (각 단계 = 단일 commit)

**Step 1 — hook 패치**
`slash-command-model-advisor.py`에 `PLAN_IMPL_PATTERN`·`is_plan_implementation()`
추가 + `main()` 분기 통합. commit.

**Step 2 — 단위 검증 (구문/로직)**
```bash
echo '{"prompt":"Implement the following plan:\n\n# foo","session_id":"default"}' \
  | python3 ~/.claude/hooks/slash-command-model-advisor.py
```
session_id `default` → JSONL 조회 불가 → fail-open으로 advisory JSON 출력 확인.
slash command 회귀: `{"prompt":"/commit"}` 입력 시 기존과 동일 동작 확인.
오탐 회귀: `{"prompt":"이 plan을 봐줘. Implement the following plan: 은 무시"}` →
prefix 앵커라 매칭 안 됨 확인.

**Step 3 — 검증 게이트 (blocking, 실세션)**
plan 모드로 사소한 plan을 만들어 승인 → 구현 컨텍스트 첫 응답에
모델 전환 advisory가 나타나는지 확인.
- 나타나면 → 완료.
- 안 나타나면 → harness prefix가 다른 것. 실제 `"Implement the following plan:"
  외 문구를 transcript에서 확인 후 `PLAN_IMPL_PATTERN` 수정. 그래도 실패 시
  `git revert`로 Step 1 되돌림.

---

## 7. 미검증 사항 / 리스크

- harness가 plan 구현 진입 시 항상 `"Implement the following plan:"` 정확한
  영문 prefix를 쓰는지는 1개 사례(이 작업)로만 확인됨. Claude Code 버전 업데이트
  시 문구 변경 가능 → Step 3 검증 게이트로 흡수, 실패 시 즉시 패턴 수정.
- 동일 세션 내 plan→구현(새 컨텍스트 아님) 케이스는 미관측. 그 경우에도
  `"Implement the following plan:"` 메시지가 오면 동일하게 발동하므로 무해.
