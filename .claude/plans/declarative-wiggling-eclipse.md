# 계획: Cynefin Framework 기반 "비즈니스 리더의 SW 공학 이해 부족" 내용 추가

## 배경

### 사용자 요청
- AI-문제점-종합-분석.md 파일에 "비즈니스나 리더들이 SW 공학을 이해하지 못하는 이유"에 대한 내용 추가
- Cynefin Is A GAMECHANGER For Software Developers.md 파일의 내용을 분석하여 추가

### 소스 파일 핵심 내용
`003-RESOURCES/AGILE/Cynefin Is A GAMECHANGER For Software Developers.md`에서 추출한 핵심 인사이트:

1. **비기술 리더들의 치명적 실수**
   - 소프트웨어 개발을 "단순한(simple/clear)" 영역으로 간주
   - 예측 가능한 인과관계(cause and effect)를 적용하려 함
   - 이로 인해 수십억~수조 달러 규모의 실수 발생

2. **소프트웨어 개발의 본질**
   - Complex Adaptive System (복합 적응 시스템)
   - 동일한 개발자에게 동일한 문제를 두 번 주더라도 매번 다른 해결책
   - Best Practice가 존재하지 않는 이유

3. **Simple vs Complicated vs Complex 혼동**
   - Simple: 인과관계 명확, 반복 가능 (생산 라인)
   - Complicated: 복잡하지만 결정론적 (조건 통제 → 예측 가능)
   - Complex: 조건을 통제해도 시스템이 적응하여 변화 (예측 불가능)
   - 리더들이 소프트웨어를 Simple/Complicated로 오해

4. **올바른 접근: Probe-Sense-Respond**
   - 작은 실험, 피드백 수집, 학습 기반 의사결정
   - 간트 차트와 장기 계획의 무용성

---

## 대상 파일 분석
`003-RESOURCES/ai/LIMITATIONS/AI-문제점-종합-분석.md`

### 기존 관련 내용
- 현재 파일에 "비즈니스", "리더" 관련 언급이 있으나 Cynefin 관점의 체계적 설명은 부재
- 섹션 18 "철학적 관점"에 일부 관련 내용 존재

### 추가 위치 검토
| 옵션 | 위치 | 장점 | 단점 |
|------|------|------|------|
| A | 섹션 18 "철학적 관점" 이후 새 섹션 | 철학적 맥락과 연결 | 구조적 위치가 후반부 |
| B | 섹션 5 "지식/역량 한계" 내 추가 | 역량 관련 주제 | AI 한계와 직접 연결 약함 |
| **C** | **섹션 7 "개발 프로세스 충돌" 직후 새 섹션** | **프로세스/조직 관점 자연스러움** | - |

**권장: 옵션 C** - 섹션 7과 8 사이에 "7.5 비즈니스 리더의 SW 공학 이해 부족: Cynefin Framework 관점" 추가

---

## 실행 계획

### 단계 1: 새 섹션 추가
- 위치: Line 587 (섹션 7 끝의 `---`) 이후, Line 589 (섹션 8 시작) 이전
- 제목: `### 6.5 비즈니스 리더의 SW 공학 이해 부족: Cynefin Framework 관점`
  (현재 섹션 7 내 하위 섹션이 6.1~6.4로 되어 있어 6.5로 추가)

### 단계 2: 추가할 내용 구조

```markdown
### 7.5 비즈니스 리더의 SW 공학 이해 부족: Cynefin Framework 관점

> **핵심 통찰**: 대부분의 비기술 리더들이 소프트웨어 개발을 "단순 시스템"으로 취급하며,
> 이는 수십억~수조 달러 규모의 조직적 실수로 이어진다.

#### Cynefin Framework와 시스템 분류

| 영역 | 특성 | 대응 패턴 | 예시 |
|------|------|-----------|------|
| Clear/Simple | 인과관계 명확, 반복 가능 | Sense-Categorize-Respond | 생산 라인 |
| Complicated | 복잡하지만 결정론적 | Sense-Analyze-Respond | 자동차 엔진 |
| **Complex** | 시스템이 적응, 예측 불가 | **Probe-Sense-Respond** | **소프트웨어 개발** |
| Chaotic | 인과관계 없음 | Act-Sense-Respond | 위기 상황 |

#### 왜 리더들은 SW 개발을 단순 시스템으로 오해하는가?

1. **제조업 사고방식의 적용**
   - 생산 라인 경험: 동일 입력 → 동일 출력
   - 간트 차트, 정확한 일정 예측 기대
   - "프로세스를 따르면 결과가 나온다" 가정

2. **창조 행위에 대한 이해 부족**
   - 동일한 개발자에게 동일한 문제를 두 번 주면 다른 솔루션
   - 개발자의 학습, 컨디션, 컨텍스트 변화
   - Best Practice가 존재하지 않는 이유

3. **복잡성 수준 혼동**
   - Complicated (복잡하지만 예측 가능) vs Complex (본질적으로 예측 불가)
   - "변수를 충분히 제어하면 예측 가능" → 틀린 가정
   - 조건을 통제해도 시스템이 적응하여 변화

#### 조직적 결과

- **계획의 실패**: 월간/연간 계획이 반복적으로 빗나감
- **책임 전가**: "개발팀이 일정을 못 지킨다" vs 시스템 본질 이해 부족
- **혼돈으로의 전락**: Complex 시스템을 Simple로 취급 → Chaotic 상태로 급락

#### 올바른 접근: Probe-Sense-Respond

```
소프트웨어 개발의 올바른 접근법
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Probe (탐색): 작은 실험 수행
2. Sense (감지): 결과 관찰, 피드백 수집
3. Respond (대응): 학습 기반 의사결정

→ Continuous Delivery, Agile, TDD의 이론적 근거
```

> "소프트웨어 개발 프로세스는 단순하고 예측 가능한 인과관계 시스템이 아니다.
> 따라서 간트 차트와 수개월, 수년 계획으로 이를 취급하려는 시도는 실패할 운명이다."
> — Dave Farley, [[Cynefin Is A GAMECHANGER For Software Developers]]
```

### 단계 3: 관련 문서 링크 추가
- 섹션 20 "관련 문서 링크"에 `[[Cynefin Is A GAMECHANGER For Software Developers]]` 추가

### 단계 4: 태그 추가
- frontmatter tags에 `frameworks/cynefin/complex-adaptive-systems` 추가

---

## 수정 대상 파일

- **수정**: `003-RESOURCES/ai/LIMITATIONS/AI-문제점-종합-분석.md`
  - Line 42 (tags): `frameworks/cynefin/complex-adaptive-systems` 태그 추가
  - Line 587 이후 (섹션 7과 8 사이): 새 섹션 `6.5 비즈니스 리더의 SW 공학 이해 부족` 추가
  - 관련 문서 링크 섹션: `[[Cynefin Is A GAMECHANGER For Software Developers]]` 링크 추가
  - 핵심 인용구 섹션: Dave Farley 인용문 추가
