# Sub-agent 위임 패턴 (Single Source of Truth)

이 문서는 `~/.claude/commands/`와 `~/.claude/skills/` 하위 사용자 작성 파일에서 참조하는 sub-agent 위임 표준 boilerplate를 정의한다.

## 왜 sub-agent 위임이 필요한가

slash command/skill의 frontmatter `model:` 필드는 **main context에서 호출 시 무시된다** (사용자 발견 규약, `~/.claude/CLAUDE.md` 참조). 즉, `model: sonnet`이라고 적어둬도 현재 세션 모델(예: Opus)로 그대로 실행되어 비용 최적화가 안 된다.

해결책: main context에서 sub-agent를 호출하면서 `model: "sonnet"` 또는 `"haiku"`를 **명시적으로** 전달한다.

## 변형 A — 동기 + Sonnet (가장 흔한 케이스)

용도: 텍스트 변환·요약·분석·생성. 사용자가 결과를 동기적으로 받음.

호출 방법:
- Tool: `Agent` (Task)
- `subagent_type: "general-purpose"`
- `model: "sonnet"` — main context 모델과 무관하게 sonnet 고정 (비용 최적화)
- `run_in_background: false` — 사용자가 결과를 동기적으로 받음
- `prompt`: 호출 파일의 "작업 프로세스" 전체 + `$ARGUMENTS` 값 + 파일 경로 + 옵션 플래그를 그대로 전달

sub-agent 결과를 받으면 호출 파일의 "작업 결과 형식"에 맞춰 사용자에게 보고. 단, sub-agent 위임 외의 추가 분석/실행은 하지 말 것.

## 변형 B — 동기 + Haiku (단순 변환·조회)

용도: 포맷 변환, 단순 분류, 도구 호출 wrapper, CLI 결과 보고. 추론 깊이가 얕은 작업.

변형 A와 동일하되 `model: "haiku"`.

## 변형 C — 백그라운드 + Sonnet (장기 작업)

용도: URL → 번역/요약/문서 생성처럼 수 분 이상 걸리는 작업.

호출 방법:
- Tool: `Agent` (Task)
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `run_in_background: true`
- progress 파일을 `.claude/summarize-progress/` (또는 호출 파일 지정 디렉토리)에 생성 후 즉시 사용자에게 알림
- 사용자는 `obsidian-jobs` 같은 상태 조회 명령으로 진행 확인

## 변형 D — 백그라운드 + Haiku

현재 사용처 없음. 정의만 두고 미래 작업에서 채택.

변형 C와 동일하되 `model: "haiku"`.

## 호출 파일에서의 reference 형식

각 command/skill은 frontmatter 종료 직후 `## 실행 모델 (필수)` 섹션을 두고 변형과 변수를 명시한다:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=$ARGUMENTS, 옵션=`--dry-run`, `--recursive`)

main context에서 직접 실행 금지.
```

## 인터랙티브 작업은 위임 안 함

multi-turn 대화로 진행되는 작업(예: 사용자 결정을 받아가며 정리하는 명령)은 sub-agent 위임 안 함. main context에서 그대로 실행한다. 이 경우 frontmatter `model:` 라인은 의미가 없으므로 제거하고, 헤더에 다음 주석을 둔다:

```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```
