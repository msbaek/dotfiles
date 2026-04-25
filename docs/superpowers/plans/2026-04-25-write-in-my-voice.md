# Write-In-My-Voice 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** im-not-ai를 `~/.claude/skills/humanize-korean/`에 글로벌 설치하고, 백명석 브런치 문체 프로필 기반으로 `/humanize-korean`(윤문)과 `/write-in-my-voice`(초안 생성) 두 스킬을 작동시킨다.

**Architecture:** im-not-ai 원본 파이프라인을 최소 수정(경로·모델)으로 글로벌 설치하고, `voice-profile-msbaek.md`를 brunch 크롤링으로 생성해 두 스킬이 공유한다. 탐지·윤문 에이전트는 sonnet으로 교체해 Opus quota를 절약하고, 의미 검증 에이전트만 opus를 유지한다.

**Tech Stack:** Claude Code skills/agents, Playwright MCP (브런치 크롤링), GitHub CLI (소스 취득)

---

## 파일 맵

```
생성/수정할 파일:

~/.claude/skills/humanize-korean/
├── SKILL.md                         [수정] 경로·모델·voice profile 참조 추가
└── references/
    ├── ai-tell-taxonomy.md          [복사] 원본 그대로
    ├── rewriting-playbook.md        [복사] 원본 그대로
    ├── web-service-spec.md          [복사] 원본 그대로
    └── voice-profile-msbaek.md      [신규] 브런치 크롤링으로 생성

~/.claude/agents/
├── ai-tell-detector.md              [복사+수정] model: opus → sonnet
├── korean-style-rewriter.md         [복사+수정] model: opus → sonnet + voice profile 참조
├── content-fidelity-auditor.md      [복사] 원본 그대로 (opus 유지)
├── naturalness-reviewer.md          [복사] 원본 그대로 (opus 유지)
└── humanize-web-architect.md        [복사] 원본 그대로

~/.claude/skills/write-in-my-voice/
└── SKILL.md                         [신규] 2단계 초안 생성 스킬

/tmp/humanize-ko/                    [런타임] _workspace 디렉토리 (임시)
```

---

## Task 1: 소스 클론 및 디렉토리 구조 구성

**Files:**
- Create: `~/.claude/skills/humanize-korean/`
- Create: `~/.claude/agents/` (없으면)
- Create: `~/.claude/skills/write-in-my-voice/`

- [ ] **Step 1: im-not-ai 클론**

```bash
cd /tmp && git clone https://github.com/epoko77-ai/im-not-ai.git
```

Expected: `/tmp/im-not-ai/` 생성, `.claude/skills/humanize-korean/`, `.claude/agents/` 포함

- [ ] **Step 2: 대상 디렉토리 생성**

```bash
mkdir -p ~/.claude/skills/humanize-korean/references
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/skills/write-in-my-voice
mkdir -p /tmp/humanize-ko
```

Expected: 4개 디렉토리 생성됨

- [ ] **Step 3: 스킬 파일 복사**

```bash
cp /tmp/im-not-ai/.claude/skills/humanize-korean/SKILL.md ~/.claude/skills/humanize-korean/SKILL.md
cp /tmp/im-not-ai/.claude/skills/humanize-korean/references/ai-tell-taxonomy.md ~/.claude/skills/humanize-korean/references/
cp /tmp/im-not-ai/.claude/skills/humanize-korean/references/rewriting-playbook.md ~/.claude/skills/humanize-korean/references/
cp /tmp/im-not-ai/.claude/skills/humanize-korean/references/web-service-spec.md ~/.claude/skills/humanize-korean/references/
```

Expected: `~/.claude/skills/humanize-korean/` 에 SKILL.md + references 3개 파일 존재

- [ ] **Step 4: 에이전트 파일 복사**

```bash
cp /tmp/im-not-ai/.claude/agents/ai-tell-detector.md ~/.claude/agents/
cp /tmp/im-not-ai/.claude/agents/korean-style-rewriter.md ~/.claude/agents/
cp /tmp/im-not-ai/.claude/agents/content-fidelity-auditor.md ~/.claude/agents/
cp /tmp/im-not-ai/.claude/agents/naturalness-reviewer.md ~/.claude/agents/
cp /tmp/im-not-ai/.claude/agents/humanize-web-architect.md ~/.claude/agents/
```

Expected: `~/.claude/agents/` 에 5개 .md 파일 존재

- [ ] **Step 5: 복사 검증**

```bash
ls ~/.claude/skills/humanize-korean/references/ && echo "---" && ls ~/.claude/agents/
```

Expected:
```
ai-tell-taxonomy.md  rewriting-playbook.md  web-service-spec.md
---
ai-tell-detector.md  content-fidelity-auditor.md  humanize-web-architect.md
korean-style-rewriter.md  naturalness-reviewer.md
```

- [ ] **Step 6: 임시 클론 정리**

```bash
rm -rf /tmp/im-not-ai
```

---

## Task 2: SKILL.md 경로 수정

**Files:**
- Modify: `~/.claude/skills/humanize-korean/SKILL.md`

원본의 하드코딩 경로 `/Users/epoko77_m5/humanize-ko/`를 교체하고, `_workspace/`를 `/tmp/humanize-ko/`로 변경한다.

- [ ] **Step 1: 경로 문자열 전체 교체**

`~/.claude/skills/humanize-korean/SKILL.md` 에서 다음 3곳을 수정한다:

**변경 1** (Phase 0):
```
# 변경 전
프로젝트 디렉토리(`/Users/epoko77_m5/humanize-ko/`)의 `_workspace/` 확인.

# 변경 후
프로젝트 디렉토리(`/tmp/humanize-ko/`)의 `_workspace/` 확인.
```

**변경 2** (Phase 2 입력 프롬프트):
```
# 변경 전
input_path: _workspace/{run_id}/01_input.txt
taxonomy_path: .claude/skills/humanize-korean/references/ai-tell-taxonomy.md

# 변경 후
input_path: /tmp/humanize-ko/{run_id}/01_input.txt
taxonomy_path: ~/.claude/skills/humanize-korean/references/ai-tell-taxonomy.md
```

**변경 3** (Phase 3 입력):
```
# 변경 전
input_path: _workspace/{run_id}/01_input.txt
detection_path: _workspace/{run_id}/02_detection.json
playbook_path: .claude/skills/humanize-korean/references/rewriting-playbook.md

# 변경 후
input_path: /tmp/humanize-ko/{run_id}/01_input.txt
detection_path: /tmp/humanize-ko/{run_id}/02_detection.json
playbook_path: ~/.claude/skills/humanize-korean/references/rewriting-playbook.md
```

**변경 4** (에이전트 정의 위치 섹션):
```
# 변경 전
- `/Users/epoko77_m5/humanize-ko/.claude/agents/` (프로젝트 로컬)
  - korean-ai-tell-taxonomist, ai-tell-detector, korean-style-rewriter, content-fidelity-auditor, naturalness-reviewer, humanize-web-architect

# 변경 후
- `~/.claude/agents/` (사용자 글로벌)
  - ai-tell-detector, korean-style-rewriter, content-fidelity-auditor, naturalness-reviewer, humanize-web-architect
```

**변경 5** (Phase 4 — TeamCreate 입력 경로):
```
# 변경 전
두 에이전트 모두 `_workspace/{run_id}/01_input.txt` + `03_rewrite.md` + `03_rewrite_diff.json`을 읽고:
- **fidelity-auditor**: `04_fidelity_audit.json` 생성
- **naturalness-reviewer**: `05_naturalness_review.json` 생성

# 변경 후
두 에이전트 모두 `/tmp/humanize-ko/{run_id}/01_input.txt` + `03_rewrite.md` + `03_rewrite_diff.json`을 읽고:
- **fidelity-auditor**: `/tmp/humanize-ko/{run_id}/04_fidelity_audit.json` 생성
- **naturalness-reviewer**: `/tmp/humanize-ko/{run_id}/05_naturalness_review.json` 생성
```

**변경 6** (Phase 6 — 최종 출력 경로):
```
# 변경 전
최종 윤문본을 `_workspace/{run_id}/final.md`로 복사.
요약 리포트 `_workspace/{run_id}/summary.md` 생성

# 변경 후
최종 윤문본을 `/tmp/humanize-ko/{run_id}/final.md`로 복사.
요약 리포트 `/tmp/humanize-ko/{run_id}/summary.md` 생성
```

- [ ] **Step 2: 변경 확인**

```bash
grep -n "epoko77_m5\|_workspace/" ~/.claude/skills/humanize-korean/SKILL.md
```

Expected: 출력 없음 (구 경로 `epoko77_m5`와 `_workspace/` 완전 제거됨)

주의: 출력이 있으면 해당 줄의 경로를 `/tmp/humanize-ko/`로 추가 교체

---

## Task 3: SKILL.md 모델 교체 (탐지기·윤문가 → sonnet)

**Files:**
- Modify: `~/.claude/skills/humanize-korean/SKILL.md`

- [ ] **Step 1: Phase 2 모델 교체 (ai-tell-detector)**

```
# 변경 전
`ai-tell-detector` 에이전트를 `Agent` 도구로 호출 (`model: "opus"`).

# 변경 후
`ai-tell-detector` 에이전트를 `Agent` 도구로 호출 (`model: "sonnet"`).
```

- [ ] **Step 2: Phase 3 모델 교체 (korean-style-rewriter)**

```
# 변경 전
`korean-style-rewriter` 에이전트를 `Agent` 도구로 호출 (`model: "opus"`).

# 변경 후
`korean-style-rewriter` 에이전트를 `Agent` 도구로 호출 (`model: "sonnet"`).
```

- [ ] **Step 3: 에이전트 호출 규칙 섹션 수정**

```
# 변경 전
**모든 Agent 호출은 `model: "opus"` 명시.**

# 변경 후
**모델 정책:** 탐지기·윤문가는 `model: "sonnet"`, 검증팀(fidelity-auditor·naturalness-reviewer)은 `model: "opus"`.
```

- [ ] **Step 4: 변경 확인**

```bash
grep -n "model:" ~/.claude/skills/humanize-korean/SKILL.md
```

Expected: sonnet 2건(Phase 2, Phase 3), opus 0건

---

## Task 4: 에이전트 파일 모델 교체

**Files:**
- Modify: `~/.claude/agents/ai-tell-detector.md`
- Modify: `~/.claude/agents/korean-style-rewriter.md`

- [ ] **Step 1: ai-tell-detector 모델 교체**

`~/.claude/agents/ai-tell-detector.md` frontmatter 수정:

```yaml
# 변경 전
model: opus

# 변경 후
model: sonnet
```

- [ ] **Step 2: korean-style-rewriter 모델 교체**

`~/.claude/agents/korean-style-rewriter.md` frontmatter 수정:

```yaml
# 변경 전
model: opus

# 변경 후
model: sonnet
```

- [ ] **Step 3: 변경 확인**

```bash
grep "model:" ~/.claude/agents/ai-tell-detector.md ~/.claude/agents/korean-style-rewriter.md
```

Expected:
```
~/.claude/agents/ai-tell-detector.md:model: sonnet
~/.claude/agents/korean-style-rewriter.md:model: sonnet
```

- [ ] **Step 4: 검증 에이전트 모델 확인 (변경 없어야 함)**

```bash
grep "model:" ~/.claude/agents/content-fidelity-auditor.md ~/.claude/agents/naturalness-reviewer.md
```

Expected: 둘 다 `model: opus`

---

## Task 5: 브런치 크롤링 및 voice-profile-msbaek.md 생성

**Files:**
- Create: `~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md`

브런치 최신 글 기준 15-20개를 Playwright MCP로 크롤링해 문체 패턴을 추출한다.

- [ ] **Step 1: 최신 글 15개 크롤링**

Playwright MCP `browser_navigate` + `browser_snapshot`으로 다음 URL들을 순차 크롤링한다:

```
https://brunch.co.kr/@cleancode/75
https://brunch.co.kr/@cleancode/74
https://brunch.co.kr/@cleancode/73
https://brunch.co.kr/@cleancode/72
https://brunch.co.kr/@cleancode/71
https://brunch.co.kr/@cleancode/70
https://brunch.co.kr/@cleancode/69
https://brunch.co.kr/@cleancode/68
https://brunch.co.kr/@cleancode/67
https://brunch.co.kr/@cleancode/66
https://brunch.co.kr/@cleancode/65
https://brunch.co.kr/@cleancode/60
https://brunch.co.kr/@cleancode/55
https://brunch.co.kr/@cleancode/50
https://brunch.co.kr/@cleancode/45
```

각 글에서 추출할 내용:
- 제목
- 첫 3단락 전문 (실제 텍스트)
- 특이한 표현/어구

크롤링 결과를 `/tmp/brunch-samples.txt`에 저장한다.

- [ ] **Step 2: 문체 패턴 분석**

수집된 15개 글 샘플을 분석해 다음 패턴을 도출한다:

분석 항목:
1. **자주 등장하는 도입부 패턴** — 어떻게 글을 시작하는가? (일화, 질문, 선언)
2. **자주 쓰는 연결어** — "그런데", "하지만", "결국", "다시 말해" 등 빈도
3. **DO 표현 목록** — 실제 텍스트에서 추출한 특징적 표현 10개 이상
4. **AVOID 패턴** — AI 번역투로 의심되는 표현 (비교 분석)
5. **단락 길이** — 평균 문장 수/단락
6. **마무리 패턴** — 결론을 어떻게 짓는가?
7. **실제 예시 문장** — 각 패턴당 원문에서 직접 인용 2-3개

- [ ] **Step 3: voice-profile-msbaek.md 작성**

분석 결과를 바탕으로 `~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md` 작성:

```markdown
# 백명석(@cleancode) 목소리 프로필
# 출처: 브런치 https://brunch.co.kr/@cleancode — 최신 15개 글 분석 (2026-04-25)

## 주요 주제 영역
- TDD / 테스트 주도 개발
- 클린 코드 / 리팩토링 / 소프트웨어 장인정신
- 개발자 커리어 / 성장 / 학습
- 팀 리더십 / 협업 / 코드 리뷰
- 소프트웨어 공학 원칙

## 서사 구조 (일관된 패턴)
1. 구체적 개인 경험 또는 비유로 시작 (야구, 자전거, 시험, 운전 등 일상 소재)
2. "왜 이게 개발에서 중요한가?"로 전환
3. 보편적 원리 또는 개념 추출
4. 실무 적용 방법으로 마무리

## 문장 리듬
- 짧은 선언문(1-2줄)으로 단락 시작
- 긴 설명문으로 전개 (50-80자 문장)
- 단락당 평균 3-5문장

## 어조 특징
- 1인칭 "나" — 개인 경험 서술
- 1인칭 복수 "우리" — 독자와 공감대 형성
- 겸손하게 시작하되 결론은 확신 있게
- 질문 던져 독자 참여 유도: "그렇다면 어떻게 해야 할까?", "여러분은 어떻게 생각하는가?"

## 표현 패턴

### ✅ DO — 백명석 특유 표현
[크롤링 결과에서 실제 문장 10개 이상 채움]
예시:
- "~라고 생각한다"
- "~인 것 같다"
- "어쩌면 ~일지도 모른다"
- "> 핵심 메시지를 인용구로 강조"
- **굵은 글씨**로 개념 강조
- (괄호로 부연 설명 추가)

### ❌ AVOID — AI 번역투/관용구 (이 글쓰기에 어울리지 않음)
- "~를 통해" → "~으로", "~해서"
- "~에 있어서" → "~에서", "~할 때"
- "가지고 있다" → "있다"
- "중요합니다", "필요합니다" (딱딱한 서술)
- "결론적으로", "요약하자면" (AI 관용구)
- "시사하는 바가 크다" (AI 관용구)
- "첫째, 둘째, 셋째" 기계적 나열

## 단락/섹션 구성
- 헤더(===)로 대주제 구분
- 소제목(---)으로 세부 주제
- 각 섹션 끝에 핵심 1문장 요약 또는 > 인용구
- 마지막에 `## 정리` 또는 `## keyword` 섹션

## 실제 예시 문장 (브런치 원문 직접 인용)
[크롤링 후 패턴별 2-3개 실제 문장 채움]

### 도입부 패턴 예시
...

### 전환부 패턴 예시
...

### 결론부 패턴 예시
...
```

- [ ] **Step 4: 임시 크롤링 파일 정리**

```bash
rm -f /tmp/brunch-samples.txt
```

- [ ] **Step 5: 파일 생성 확인**

```bash
wc -l ~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md
```

Expected: 70줄 이상 (실제 예시 문장 포함시)

---

## Task 6: korean-style-rewriter에 voice profile 통합

**Files:**
- Modify: `~/.claude/agents/korean-style-rewriter.md`

윤문가가 일반 자연 한국어가 아닌 백명석 목소리를 타겟으로 윤문하도록 지침을 추가한다.

- [ ] **Step 1: voice profile 참조 추가**

`~/.claude/agents/korean-style-rewriter.md`의 `## 핵심 역할` 섹션 뒤에 다음 섹션 추가:

```markdown
## 목소리 프로필 (Voice Profile)

윤문 시 아래 프로필을 참조해 일반적인 "자연스러운 한국어"가 아닌 저자 고유의 목소리로 변환한다.

**프로필 경로:** `~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md`

**적용 원칙:**
1. AI 티 제거 후 빈 자리를 profile의 DO 패턴으로 채운다.
2. AVOID 목록의 표현은 AI-tell로 추가 탐지해 함께 수정한다.
3. 서사 구조(경험→원리→실무)가 유지되도록 전체 흐름 점검.
4. 단, **의미 불변 원칙은 최우선** — voice profile 적용이 의미 훼손으로 이어지면 적용 중단.
```

- [ ] **Step 2: 적용 확인**

```bash
grep -n "voice\|프로필\|voice-profile" ~/.claude/agents/korean-style-rewriter.md
```

Expected: 추가한 섹션 관련 줄 3개 이상

---

## Task 7: write-in-my-voice 스킬 작성

**Files:**
- Create: `~/.claude/skills/write-in-my-voice/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`~/.claude/skills/write-in-my-voice/SKILL.md` 생성:

```markdown
---
name: write-in-my-voice
description: 백명석(@cleancode)의 브런치 글쓰기 스타일로 기술 블로그 초안을 생성하는 스킬.
  주제 또는 키워드를 입력하면 voice-profile-msbaek.md를 참조해 2단계로 초안을 작성한다.
  트리거 — "/write-in-my-voice", "내 말투로 써줘", "브런치 스타일로 초안", "내 목소리로 글",
  "cleancode 스타일", "백명석 스타일 블로그".
---

# Write-In-My-Voice — 백명석 스타일 글쓰기 어시스턴트

**Voice Profile 경로:** `~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md`

이 스킬은 **2단계 파이프라인**으로 동작한다. 구조를 먼저 확정하고 본문을 작성해
사용자가 방향을 조정할 기회를 갖는다.

---

## Phase 1: 구조 설계

**실행 모드:** 단일 (메인 세션)

1. `voice-profile-msbaek.md`를 읽어 주제 영역·서사 구조·어조 특징을 파악한다.
2. 사용자 입력(주제/키워드)을 분석한다.
3. **제목 후보 3개를 제시한다:**
   - 선언형 (예: "TDD는 설계 행위다")
   - 질문형 (예: "왜 TDD는 배우기 어려울까?")
   - 경험 서사형 (예: "처음 TDD를 만났을 때")
4. **섹션 구조 초안을 제시한다** (서사 구조: 경험 → 원리 → 실무):
   ```
   ## [도입: 개인 경험 또는 비유]
   ## [핵심 질문: 왜 이게 중요한가]
   ## [원리: 보편적 개념 추출]
   ## [실무: 어떻게 적용할까]
   ## 정리 / keyword
   ```
5. 사용자 피드백을 기다린다.
   - 제목 선택 또는 수정 요청
   - 섹션 구조 변경 요청
   - 승인("ok", "좋아", "이대로") 시 Phase 2 진행

---

## Phase 2: 본문 작성

**실행 모드:** 단일 (메인 세션)

사용자가 승인한 구조 기반으로 섹션별 본문을 작성한다.

**Voice Profile 적용 규칙:**

1. **도입부**: 구체적 개인 경험 또는 일상 비유(야구, 시험, 운전 등)로 시작
2. **문장 리듬**: 짧은 선언문 → 긴 설명문 교대. 단락당 3-5문장
3. **어조**: "나"(경험 서술) + "우리"(독자 공감) 교차
4. **DO 패턴 적용**: profile의 특징적 표현 사용
5. **AVOID 패턴 회피**: 번역투·AI 관용구 사용 금지
6. **강조 형식**: `>` 인용구로 핵심 강조, **굵은 글씨** 개념 강조
7. **마무리**: 겸손하게 시작하되 결론은 확신 있게. `## 정리` 또는 `## keyword` 섹션 포함

**출력 형식:**
- 브런치 에디터 호환 마크다운
- 헤더: `===`(대주제), `---`(소주제)
- 전체 분량: 800-1500자 (브런치 표준 칼럼 분량)
- 마지막에 권장 후속 작업 안내:
  ```
  > 💡 이 초안을 `/humanize-korean`에 넣으면 AI 티를 추가로 제거할 수 있습니다.
  ```

---

## 사용 예시

```
/write-in-my-voice TDD를 처음 배울 때의 어려움
/write-in-my-voice 코드 리뷰 문화 만들기
/write-in-my-voice 기술 부채를 바라보는 관점
```

## 권장 2단계 워크플로우

```
1. /write-in-my-voice <주제>   →  백명석 스타일 초안 생성
                                    ↓
2. /humanize-korean             →  AI 티 추가 제거 + 목소리 강화
```
```

- [ ] **Step 2: 파일 생성 확인**

```bash
ls -la ~/.claude/skills/write-in-my-voice/SKILL.md && wc -l ~/.claude/skills/write-in-my-voice/SKILL.md
```

Expected: 파일 존재, 70줄 이상

---

## Task 8: 동작 검증

**검증 1: humanize-korean 경로 검증**

- [ ] **Step 1: Claude Code 새 세션에서 스킬 로드 확인**

Claude Code를 실행해 다음을 입력:
```
/humanize-korean
```

Expected: 스킬이 로드되고 "AI 티 제거 오케스트레이터" 설명이 표시됨
Failure: "skill not found" 또는 오류 → SKILL.md 경로 재확인

- [ ] **Step 2: 샘플 텍스트로 윤문 테스트**

다음 샘플(AI 번역투 포함)을 입력해 테스트:

```
이 글을 통해 TDD에 대해 알아보도록 하겠습니다. TDD는 테스트 주도 개발이라는
것으로, 개발자들이 코드를 작성하기 전에 테스트를 먼저 작성하는 방법론입니다.
첫째, 테스트를 먼저 작성합니다. 둘째, 테스트를 통과하는 코드를 작성합니다.
셋째, 리팩토링을 진행합니다. 이를 통해 코드 품질을 향상시킬 수 있습니다.
결론적으로, TDD는 매우 중요한 개발 방법론이라고 할 수 있습니다.
```

Expected 결과:
- `02_detection.json` 에 "~를 통해"(A카테고리), "첫째·둘째·셋째"(C카테고리), "결론적으로"(D카테고리) 탐지
- `03_rewrite.md` 에 백명석 스타일로 윤문된 결과
- 변경률 15-35% 범위
- 윤문 결과에 profile의 DO 패턴 반영 확인

Failure 시나리오:
- `/tmp/humanize-ko/` 쓰기 권한 오류 → `mkdir -p /tmp/humanize-ko` 실행
- 에이전트 not found → `~/.claude/agents/` 경로 확인

**검증 2: write-in-my-voice 동작 확인**

- [ ] **Step 3: 스킬 로드 확인**

```
/write-in-my-voice TDD를 처음 배울 때의 어려움
```

Expected Phase 1: 제목 3개 후보 + 섹션 구조 제시
Expected Phase 2 (승인 후): 800-1500자 분량 초안, 브런치 마크다운 형식

- [ ] **Step 4: Voice Profile 반영 확인**

생성된 초안에서 다음을 확인:
- "나"/"우리" 교차 사용 ✓
- 개인 경험/비유로 시작 ✓
- AVOID 패턴 없음 ("~를 통해", "결론적으로" 등) ✓
- > 인용구 또는 **굵은 글씨** 강조 ✓
- ## keyword 또는 ## 정리 섹션 ✓

---

## 완료 기준

모든 Task 완료 후 확인:

```bash
# 스킬 파일 존재 확인
ls ~/.claude/skills/humanize-korean/SKILL.md
ls ~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md
ls ~/.claude/skills/write-in-my-voice/SKILL.md

# 에이전트 파일 확인
ls ~/.claude/agents/ai-tell-detector.md
ls ~/.claude/agents/korean-style-rewriter.md

# 모델 설정 확인
grep "model:" ~/.claude/agents/ai-tell-detector.md        # sonnet
grep "model:" ~/.claude/agents/korean-style-rewriter.md   # sonnet
grep "model:" ~/.claude/agents/content-fidelity-auditor.md  # opus
grep "model:" ~/.claude/agents/naturalness-reviewer.md      # opus

# 경로 하드코딩 없음 확인
grep "epoko77_m5" ~/.claude/skills/humanize-korean/SKILL.md  # 출력 없어야 함
```
