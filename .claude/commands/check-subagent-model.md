---
argument-hint: "[project-path] [-f FOLDER] [--last N] [--include-main]"
description: "최근 agent 호출에서 실제 사용된 모델을 확인 (skill/command의 model 설정이 실제로 적용됐는지 검증). 기본은 sub-agent, --include-main 시 main session도 포함"
---

# Sub-agent Model 검증 - $ARGUMENTS

최근 sub-agent JSONL 파일을 읽어 실제 API 호출에 사용된 모델과 함께 폴더·git branch·작업 요약을 보고한다.

## 실행

`~/.claude/bin/check-subagent-model.py`를 Bash로 직접 호출하고, 출력 그대로 사용자에게 보여준다.

```bash
python3 ~/.claude/bin/check-subagent-model.py $ARGUMENTS
```

## 결과 형식

각 항목당 4줄:

1. `N. 시각  agent-ID`
2. `main <모델칩>  → sub <모델칩>` — main agent 모델(sub-agent 호출 시점 직전 기준) → sub 모델 (sonnet=초록·opus=노랑·haiku=청록)
3. `📁 ~/짧은경로 (branch)` — branch는 main이 아닐 때만
4. `└─ 첫 user prompt 첫 줄(80자)`

**main 모델 정확도**: sub-agent의 첫 timestamp 직전 main JSONL에서 마지막으로 사용된 모델. 같은 main 세션에서 모델 전환(예: Opus 계획 → Sonnet 실행)된 경우에도 해당 sub가 어떤 main 컨텍스트에서 호출됐는지 추적 가능. 같은 main JSONL은 캐싱되어 중복 호출 시에도 빠름.

## 옵션 (스크립트 인자로 그대로 전달)

- `[project-path]`: 특정 Claude project key 경로 (예: `/Users/msbaek/.claude/projects/-Users-msbaek-git-foo`). 기본값은 전체 스캔.
- `-f NAME` / `--folder NAME`: `cwd` 경로에 substring 매치되는 항목만. 예: `-f BO-query`, `-f vault-intelligence`, `-f msbaek_vault`
- `--last N`: 최근 N개 파일 확인 (기본 10)
- `--include-main`: main session JSONL도 포함. 폴더에서 오늘 sub-agent 호출이 없었는데 main 작업만 있었을 때 유용 (`[main]` 태그로 표시)
- `--no-color`: ANSI 컬러 비활성화 (`NO_COLOR` 환경변수도 존중)

## 터미널에서 직접 사용

스킬과 동일한 동작을 터미널에서도 실행 가능:

```bash
~/.claude/bin/check-subagent-model.py --last 20
~/.claude/bin/check-subagent-model.py -f BO-query --last 5
~/.claude/bin/check-subagent-model.py --last 5 --no-color > audit.txt
```
