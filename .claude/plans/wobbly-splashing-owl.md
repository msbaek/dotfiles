# Skill 분리 계획

## 목표

기존 `newsletter-generator` skill을 2개의 독립적인 skill로 분리:

1. **daily-work-logger**: 매일 업무 시작 전 어제 작업 내역 정리
2. **weekly-newsletter**: 토요일 오전 외부 공유용 뉴스레터 생성

## Skill 1: daily-work-logger

### 목적
- 매일 아침 업무 시작 전 실행
- 어제 작성/수정된 문서들에서 **업무 수행 관련 내용** 추출
- 해당 날짜의 Daily Note에 반영

### 입력 소스
| 소스 | 경로 | 추출 내용 |
|------|------|-----------|
| 미팅 노트 | `notes/dailies/YYYY-MM-DD-*.md` | 미팅 결정사항, 액션 아이템 |
| 기술 문서 | `001-INBOX/`, `003-RESOURCES/` | 업무 적용 가능한 항목 |
| 어제 수정 문서 | vault 전체 (어제 수정) | 업무 관련 내용 |

**참고**: coffee-time은 weekly-newsletter에서만 사용 (daily에서는 제외)

### 출력
- 파일: `notes/dailies/YYYY-MM-DD.md` (어제 날짜)
- 기존 내용 유지, 중복 없이 추가

### 추출 기준
- [ ] 후속 액션 / TODO
- [ ] 미팅 결정사항
- [ ] 업무 적용 검토 항목
- [ ] 일정 관련 사항

---

## Skill 2: weekly-newsletter

### 목적
- 매주 토요일 오전 실행
- **기술적, 리더십적으로 외부 공유할 만한 내용**을 뉴스레터로 작성
- 여러 소스를 종합하여 풍부한 내용 구성

### 입력 소스 (모두 사용)
| 소스 | 경로 | 추출 내용 |
|------|------|-----------|
| Daily Notes | `notes/dailies/` (월~금) | 주간 업무 하이라이트, 학습 내용 |
| coffee-time | `coffee-time/` (해당 주) | 기술 인사이트, 리더십 토론 |
| 주간 작성 문서 | vault 전체 (해당 주 수정) | 기술 아티클, 학습 노트 등 |

### 출력
- 파일: `newsletters/YYYY-WXX-newsletter.md`

### 추출 기준 (외부 공유 적합성)
- [ ] 기술 트렌드 / 새로운 개념
- [ ] 리더십 / 매니지먼트 인사이트
- [ ] 학습 방법론
- [ ] 업계 동향 분석
- [ ] ❌ 내부 업무 세부사항 제외
- [ ] ❌ 민감한 비즈니스 정보 제외

---

## 의존 관계

```
daily-work-logger (매일)
        ↓
    dailies/YYYY-MM-DD.md
        ↓
weekly-newsletter (토요일)
        ↓
    newsletters/YYYY-WXX-newsletter.md
```

---

## 실행 계획

### Step 1: daily-work-logger skill 생성
- 파일: `~/.claude/skills/daily-work-logger/SKILL.md`
- 기존 newsletter-generator에서 Daily Note 관련 로직 분리

### Step 2: weekly-newsletter skill 생성
- 파일: `~/.claude/skills/weekly-newsletter/SKILL.md`
- dailies 참조 로직 추가
- 외부 공유 적합성 필터링 기준 명시

### Step 3: 기존 newsletter-generator 삭제
- `~/.claude/skills/newsletter-generator/` 폴더 삭제

---

## 검증 방법
- daily-work-logger: 어제 날짜 Daily Note에 업무 내용 추가 확인
- weekly-newsletter: dailies 내용이 뉴스레터에 반영되는지 확인
