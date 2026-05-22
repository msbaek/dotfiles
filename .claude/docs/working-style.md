
## Working with me on Opus 4.7

### Problem-first workflow (가장 중요)

비자명한 작업은 다음 순서로. 단계 건너뛰지 말 것.

1. **문제 정의** — 무엇을 / 왜 / 누구를 위해. 모호하면 질문.
2. **승인 조건(acceptance criteria) 명시** — "끝났다"의 정의. TDD test-first의 일반화.
3. **시나리오 분해 (Test List)** — 처리할 시나리오·슬라이스 단위로 나열 (happy path · edge cases).
   _컴포넌트·계층 분해 아님 — 그건 4단계에서 자연스럽게 드러남._
4. **Walking Skeleton** — 가장 단순한 시나리오를 E2E로 먼저 동작.
   _모든 계층 연결 + 각 계층 최소 구현. 완벽주의 금지._
   _도메인·해법 경로가 불확실하면 `spike-and-stabilize` skill로 Quick Pass 후 이 흐름으로 회귀._
5. **슬라이스 추가로 정교화** — 한 번에 하나씩. 직전 슬라이스 동작 확인 후 다음.
6. **전체 개선** — 모든 슬라이스 E2E 동작 후에만 ("Make it right, make it fast").

**왜 분해와 E2E가 충돌 없이 결합되는가**: 분해는 _너비_(시나리오), E2E는 _깊이_(계층 관통). 두 축은 직교. "잘게 쪼갠 시나리오를 하나씩 E2E로 처리"가 결합 방식.

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

- **기본 effort**: `xhigh` (Claude Code 신규 기본값). `max`는 의도적으로만 (overthinking 위험). 작업 중 토글 가능.
- **Adaptive thinking**: 더 많은 사고는 "신중하고 단계적으로 생각", 더 적은 사고는 "확신 안 서면 직접 응답".

### Tool usage shifts (4.7 default 동작 인식)

- **Tool 호출 줄어듦**: 적극적 search 원하면 "언제·왜 tool 사용" 명시.
- **Subagent 생성 줄어듦**: 병렬 fan-out 이점 시 "같은 turn 내 여러 subagent 생성" 명시.

### Skill + model boundary (사용자 발견 규약)

- skill frontmatter `model` 필드는 main context 호출 시 **무시됨** — 현재 세션 모델로 실행.
- 비용 의도(예: Haiku로 실행할 의도) 의미 있으면 **sub-agent 경유** (Agent 도구로 위임). 단순 대화는 main context OK.

---
