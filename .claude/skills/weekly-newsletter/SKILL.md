---
name: weekly-newsletter
description: |
  Obsidian vault에서 이번 주(월~금) 작성/수정된 글들을 모아 뉴스레터 생성.
  기술적, 리더십적으로 외부에 공유할 만한 내용을 선별하여 정리.
  dailies(daily-work-logger 출력), coffee-time, 주간 작성 문서 모두 참조.
  사용자 프로필(~/git/aboutme/)을 참고하여 톤앤매너 조정.
  "뉴스레터 만들어줘", "이번 주 글 정리해줘", "weekly digest" 등의 요청 시 자동 적용.
---

# Weekly Newsletter Skill

## 개요

매주 토요일 오전 실행하여 **기술적, 리더십적으로 외부 공유할 만한 내용**을 뉴스레터로 작성하는 skill.

여러 소스를 종합하여 풍부한 내용 구성:
- Daily Notes (daily-work-logger 출력)
- coffee-time 주간 노트
- vault 전체 주간 작성 문서

## 실행 시점

- **실행**: 매주 토요일 오전
- **대상 기간**: 해당 주 월요일 ~ 금요일 (5일간)
- **출력**: `newsletters/YYYY-WXX-newsletter.md`

## 경로 정보

| 항목 | 경로 |
|------|------|
| vault | `~/DocumentsLocal/msbaek_vault/` |
| coffee-time | `~/DocumentsLocal/msbaek_vault/coffee-time` (→ `~/git/kt4u/coffee-time/`) |
| dailies | `~/DocumentsLocal/msbaek_vault/notes/dailies/` |
| newsletters | `~/DocumentsLocal/msbaek_vault/newsletters/` |
| 사용자 프로필 | `~/git/aboutme/AI-PROFILE.md` |

## 입력 소스 (모두 사용)

| 소스 | 경로 | 추출 내용 |
|------|------|-----------|
| Daily Notes | `notes/dailies/` (월~금) | 주간 업무 하이라이트, 학습 내용 |
| coffee-time | `coffee-time/` (해당 주) | 기술 인사이트, 리더십 토론 |
| 주간 작성 문서 | vault 전체 (해당 주 수정) | 기술 아티클, 학습 노트 등 |

## 실행 단계

### Step 1: 주간 날짜 범위 계산

```bash
# 토요일 기준 이번 주 월~금 날짜 계산
MONDAY=$(date -v-5d +%Y-%m-%d)
FRIDAY=$(date -v-1d +%Y-%m-%d)
WEEK_NUM=$(date +%Y-W%V)

echo "대상 기간: $MONDAY ~ $FRIDAY ($WEEK_NUM)"
```

### Step 2: 주간 수정 파일 탐색

```bash
# 이번 주 수정된 파일 찾기 (월~금)
find ~/DocumentsLocal/msbaek_vault -name "*.md" \
  -newermt "$MONDAY" ! -newermt "$(date +%Y-%m-%d)"

# coffee-time 폴더에서 이번 주 파일들
find ~/DocumentsLocal/msbaek_vault/coffee-time -name "*.md" \
  -newermt "$MONDAY" ! -newermt "$(date +%Y-%m-%d)"

# Daily Notes (월~금)
ls ~/DocumentsLocal/msbaek_vault/notes/dailies/${MONDAY}*.md \
   ~/DocumentsLocal/msbaek_vault/notes/dailies/$(date -v-4d +%Y-%m-%d)*.md \
   ~/DocumentsLocal/msbaek_vault/notes/dailies/$(date -v-3d +%Y-%m-%d)*.md \
   ~/DocumentsLocal/msbaek_vault/notes/dailies/$(date -v-2d +%Y-%m-%d)*.md \
   ~/DocumentsLocal/msbaek_vault/notes/dailies/${FRIDAY}*.md 2>/dev/null
```

### Step 3: 주요 문서 읽기

1. **Daily Notes**: `notes/dailies/YYYY-MM-DD.md` (월~금) - daily-work-logger 출력
2. **coffee-time**: 해당 주의 모든 커피타임 노트
3. **기술 아티클**: `001-INBOX/`, `003-RESOURCES/` 폴더의 수정된 문서
4. **학습 노트**: `000-SLIPBOX/` 폴더의 수정된 문서

### Step 4: 외부 공유 적합성 필터링

**포함 (외부 공유 적합):**
| 분류 | 예시 |
|------|------|
| 기술 트렌드 | SDD, AI 코딩 도구, 새로운 아키텍처 패턴 |
| 리더십 인사이트 | 효과적인 매니저 특징, 팀 운영 노하우 |
| 학습 방법론 | 조각 지식 전략, AI 활용 학습법 |
| 업계 동향 분석 | 하이프 사이클, 재본스 역설 |

**제외:**
| 분류 | 이유 |
|------|------|
| 내부 업무 세부사항 | 민감한 비즈니스 정보 |
| 회사 고유 프로세스 | 내부 전용 |
| 개인 일정/TODO | 공유 부적합 |
| 고객/파트너 정보 | 기밀 사항 |

### Step 5: 주간 뉴스레터 작성

**파일**: `newsletters/YYYY-WXX-newsletter.md`

**구조**:
```markdown
---
id: YYYY-WXX-newsletter
aliases:
  - YYYY년 XX주차 뉴스레터
tags:
  - newsletter
  - weekly-digest
created_at: YYYY-MM-DD
period: YYYY-MM-DD ~ YYYY-MM-DD
---

# Weekly Digest - YYYY년 XX주차

> "핵심 인용문" - 출처

**기간**: MM월 DD일(월) ~ MM월 DD일(금)

---

## 이번 주 커피타임 하이라이트

### [날짜1] - [주제]
- 핵심 내용 요약
- 교훈과 인사이트

### [날짜2] - [주제] (있는 경우)
- 핵심 내용 요약

---

## 기술 트렌드

### [기술명 1]
- 핵심 개념 설명
- 기존 방식과의 비교

### [기술명 2] (있는 경우)
- 핵심 개념 설명

---

## 리더십 & 조직 인사이트

- 효과적인 접근법
- 실패/성공 사례

---

## 학습 방법론

- 핵심 전략
- AI 활용 방법

---

## 이번 주 핵심 교훈

1. 교훈 1
2. 교훈 2
3. 교훈 3

---

## 다음 주 포커스

- [ ] 포커스 영역 1
- [ ] 포커스 영역 2

---

## Related Notes

- [[커피타임 노트 1]]
- [[기술 아티클]]
- [[학습 노트]]
```

## 사용자 프로필 반영

`~/git/aboutme/AI-PROFILE.md`를 참고하여:

- **개발 철학**: "예측보다 실험" - 실험과 반복 강조
- **성장 철학**: 전문가 집단 추구
- **AI 활용**: Pair Programming Partner
- **리더십**: 지식 공유와 교육 중시
- **기술 스택**: TDD, Clean Code, Refactoring

## 뉴스레터 톤앤매너

1. **CTO 관점의 Weekly Digest**
2. **점진적 개선(Incremental) 관점** 반영
3. **TDD/Clean Code 철학**과 연결
4. **실용적 인사이트** 중심
5. **핵심 인용문**으로 섹션 강조
6. **다음 주 포커스** 섹션으로 연속성 제공

## 커피타임 파일 패턴

coffee-time 폴더의 파일명 패턴:
- `YYYY. M. DD. 커피타임.md`
- 예: `2026. 1. 14. 커피타임.md`

## 검증 체크리스트

- [ ] 이번 주(월~금) 날짜 범위 정확한지
- [ ] coffee-time 해당 주 노트 모두 포함 여부
- [ ] dailies 내용 반영 여부
- [ ] 외부 공유 부적합 내용 제외 여부
- [ ] 마크다운 포맷 정상 렌더링
- [ ] Related Notes 링크 정확성
- [ ] 주차 번호(Week Number) 정확한지

## 자주 사용하는 명령어

```bash
# 이번 주 월~금 날짜 확인 (토요일 기준)
echo "월요일: $(date -v-5d +%Y-%m-%d)"
echo "금요일: $(date -v-1d +%Y-%m-%d)"
echo "주차: $(date +%Y-W%V)"

# 이번 주 수정된 파일 찾기
find ~/DocumentsLocal/msbaek_vault -name "*.md" -mtime -6 -mtime +0

# coffee-time 폴더 이번 주 파일
ls -lt ~/DocumentsLocal/msbaek_vault/coffee-time/ | head -10

# Daily Notes 확인
ls ~/DocumentsLocal/msbaek_vault/notes/dailies/

# newsletters 폴더 확인
ls ~/DocumentsLocal/msbaek_vault/newsletters/
```

## 주간 흐름 예시

```
토요일 아침 실행 시:
├── 대상 기간: 1/13(월) ~ 1/17(금)
├── 주차: 2026-W03
├── 입력 소스:
│   ├── dailies: 2026-01-13.md ~ 2026-01-17.md
│   ├── coffee-time: 2026. 1. 14. 커피타임.md, 2026. 1. 16. 커피타임.md
│   └── 주간 작성 문서: 001-INBOX/, 003-RESOURCES/ 등
├── 필터링: 외부 공유 적합 내용만 선별
└── 출력: newsletters/2026-W03-newsletter.md
```

## 의존 관계

```
daily-work-logger (매일)
        ↓
    dailies/YYYY-MM-DD.md
        ↓
weekly-newsletter (토요일) ← 이 skill
        ↓
    newsletters/YYYY-WXX-newsletter.md
```

## 관련 Skill

- `daily-work-logger`: 매일 업무 내역 정리 (이 skill의 입력 소스)
- `obsidian-vault`: vault 작업 기본 가이드
