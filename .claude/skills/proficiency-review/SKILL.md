---
name: proficiency-review
description: |
  pending 큐의 미분석 세션을 배치 분석해 영역별 숙련도 변경 제안 → 사용자 확정.
  LLM 분류기(Haiku sub-agent)로 S2/S4/S5 신호를 추출하고, 결정적 공식으로 점수를 계산.
  confirmed 표는 사용자 승인 후에만 변경. locked 행은 절대 건드리지 않음.
argument-hint: "[--dry-run] [--session <session-id>]"
---

# Proficiency Review

세션 JSONL에 기록된 사용자 질문 패턴으로 숙련도 지표를 갱신한다.

## Step 1: 사전 확인

```bash
ls ~/.claude/proficiency.md 2>/dev/null || echo "MISSING"
ls ~/.claude/state/proficiency/pending/ 2>/dev/null | wc -l
```

- `proficiency.md` 없으면 → `/proficiency-init` 먼저 실행하도록 안내 후 중단.
- pending 파일 0개이고 `--session` 미지정 → "분석할 세션이 없습니다." 안내 후 중단.

## Step 2: pending 큐 로드

```bash
ls ~/.claude/state/proficiency/pending/*.json 2>/dev/null
```

`--session <id>` 지정 시 해당 파일만 처리. 미지정 시 전체 처리.

각 마커 파일에서: `session_id`, `transcript`, `project_key` 추출.

## Step 3: 사용자 프롬프트 추출

각 transcript JSONL에서 `type:"user"` 레코드의 `message` 필드를 추출:

```bash
# transcript 경로는 마커 JSON의 'transcript' 필드
python3 -c "
import json, sys
path = sys.argv[1]
prompts = []
with open(path) as f:
    for line in f:
        try:
            r = json.loads(line)
            if r.get('type') == 'user':
                msg = r.get('message', '')
                if isinstance(msg, list):
                    text = ' '.join(p.get('text','') for p in msg if isinstance(p,dict) and p.get('type')=='text')
                elif isinstance(msg, str):
                    text = msg
                else:
                    text = ''
                if text.strip():
                    prompts.append(text.strip())
        except: pass
print(json.dumps(prompts, ensure_ascii=False))
" <transcript_path>
```

**오염 신호 필터** (제외 조건):
- 코드 블록만으로 이뤄진 프롬프트 (```로만 구성)
- 길이 10자 미만 (ok, 감사, 진행해줘 등)
- "테스트로", "동료 대신", "예시로" 키워드 포함

## Step 4: Haiku Sub-agent로 신호 분류

현재 글로벌 CLAUDE.md 규약에 따라 **sub-agent 경유**로 `claude-haiku-4-5` 모델 호출.

`Agent` 도구로 sub-agent 생성 시 아래 프롬프트를 전달:

```
You are a proficiency signal classifier. For each user prompt below, classify:

S2 (question_type): "concept" | "application" | "troubleshoot"
  - concept: asking what X is, how X works in general
  - application: asking how to apply X to a specific situation
  - troubleshoot: debugging, fixing, diagnosing a problem

S4 (term_accuracy): "accurate" | "vague" | "misused"
  - accurate: uses technical terms correctly and precisely
  - vague: vague or imprecise terms
  - misused: uses wrong terms or conflates concepts

S5 (abstraction_level): "symptom" | "mechanism"
  - symptom: describes surface behavior ("button doesn't work")
  - mechanism: asks about underlying mechanism ("why does useEffect re-run when…")

Domain lexicon for area attribution:
<paste Domain Lexicon table from proficiency.md>

For each prompt, also attribute it to 1+ areas from the lexicon.
Output a JSON array. One object per prompt:
{
  "idx": 0,
  "areas": ["react-hooks"],
  "S2": "concept",
  "S4": "accurate",
  "S5": "mechanism",
  "evidence": "quoted phrase that drove the classification"
}

Prompts to classify:
<paste prompts as numbered list>
```

Sub-agent 결과를 JSON 배열로 수신.

## Step 5: 점수 계산 (결정적 공식)

수신한 분류 결과로 영역별 점수를 계산:

**신호 점수 정규화 (0–100)**:
```
S2: troubleshoot=90, application=65, concept=30
S4: accurate=85,     vague=45,      misused=15
S5: mechanism=85,    symptom=30
S1: (area question count) / total prompts * 100  [보조]
S3: repeated_area_ratio * -40  [감쇠, 보조]
S6: follow_up_ratio * -20      [보조]
```

**가중합**:
```
raw = 0.30*S2 + 0.25*S4 + 0.15*S5 + 0.05*S1 + 0.20*(100-S3) + 0.05*(100-S6)
```

**Shrinkage (prior 방어)**:
```
prior = 기존 confirmed 점수 (없으면 50)
adjusted = (n*raw + 5*prior) / (n + 5)    # k=5
```

여기서 n = 이번 세션에서 해당 영역에 귀속된 프롬프트 수.

**점수 변동 상한**: adjusted와 prior의 차이가 ±10 초과 시 ±10으로 클리핑.

**effective_n 계산** (decay 반영):
```
days = (today - last_confirmed_date).days
effective_n = existing_n * 0.5^(days / 90) + n
```

**Confidence 등급**:
- high: effective_n > 20
- medium: 5 ≤ effective_n ≤ 20
- low: effective_n < 5 또는 seed

**밴드 결정**:
- 81–100 → Expert
- 61–80 → Proficient
- 41–60 → Competent
- 21–40 → Adv.Beginner
- 0–20 → Novice

## Step 6: 후보 영역 처리

Lexicon에 없는 영역이 n≥3으로 등장 시 → "후보 영역" 표에 추가 (점수 미부여).
n≥5 도달 시 → confirmed 승격 후보로 표시.

## Step 7: 변경 제안 출력

`--dry-run` 아니면 `~/.claude/proficiency.md`의 "변경 로그 (pending)" 섹션에 제안 추가:

```
## 변경 로그 (pending — 다음 review에서 검토)
- 2026-05-22 react-hooks 25→31 (+6) [confidence:medium, n:8, evidence:"useEffect cleanup이 언제 실행되는지 모르겠어"]
- 2026-05-22 java-spring 85→88 (+3) [confidence:high, n:45]
- 2026-05-22 [후보] databricks-streaming 발견 (n=3, keywords: watermark, trigger)
- 2026-05-22 complex-sql 점수 유지 (locked — 변경 skip)
```

사용자에게 제안 요약 출력:
```
📊 /proficiency-review 분석 결과
세션 N개, 프롬프트 M개 분석

변경 제안:
  react-hooks: 25 → 31 (+6) [medium conf]
    근거: "useEffect cleanup이 언제 실행되는지 모르겠어" → S2:concept, S5:mechanism
  java-spring: 85 → 88 (+3) [high conf]
    근거: application/troubleshoot 우세, accurate 용어 사용

후보 영역 (미확정):
  databricks-streaming: n=3 (concept 2, 반복 1)

locked 영역 변경 시도: complex-sql → skipped

각 제안을 승인(y)/거부(n)/수동수정(m)하시겠습니까?
```

## Step 8: 사용자 확정

각 제안에 대해 사용자 응답 수신:
- `y` / 승인 → confirmed 표에 점수·밴드·confidence·n·날짜 갱신
- `n` / 거부 → pending 로그에 `[rejected]` 표시, negative example로 기록
- `m` / 수정 → 사용자가 제시한 점수로 반영, 사유는 `manual-calibration`

수동 보정 신호 기록 (거부 시):
```
## Negative Examples (재제안 억제)
- 2026-05-22 react-hooks +6 rejected (이유: "동료 대신 물어본 세션")
```

## Step 9: 큐 비우기

처리 완료된 pending 파일 삭제:
```bash
rm ~/.claude/state/proficiency/pending/<session-id>.json
```

`--dry-run` 시 삭제하지 않음.

## Step 10: 완료 보고

```
✅ proficiency-review 완료
  갱신: N개 영역 / 거부: M개 / 후보 추가: K개
  ~/.claude/proficiency.md 업데이트됨
```

---

## 수동 보정 (사용자 직접 ±1밴드 조정)

`/proficiency-review adjust <영역> <+1|-1>` 형태로 호출 시:
- 해당 영역 점수를 ±10 조정
- 변경 로그에 `manual-calibration` 사유 기록
- "리뷰가 너무 얕음/깊음" 피드백 루프에 사용
