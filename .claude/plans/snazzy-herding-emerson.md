# 계획: AI-문제점-종합-분석.md 개발자 대체 시도 역사 보완

## 목표
`AI-문제점-종합-분석.md` 문서의 "### 1.1 개발자 불필요 예언의 역사" 섹션에 누락된 개발자 대체 시도들을 추가

## 대상 파일
`/Users/msbaek/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/LIMITATIONS/AI-문제점-종합-분석.md`

## 현재 상태
현재 표에 포함된 기술 (8개):
- 1954 FORTRAN, 1962 COBOL, 1972 C, 1985 C++
- 1992 Visual Programming, 2008 Cloud, 2010 DevOps, 2025 GenAI

## 추가할 기술들 (4개 - 확정)

**사용자 선택: 핵심 4개만 추가, 기존 Visual Programming과 별도 유지**

1. **1981 4GL** - "프로그래머 없는 개발" 최초 공식화 (James Martin)
2. **1982 CASE Tools** - 가장 야심 찬 시도이자 가장 명확한 실패
3. **2001 MDA** - CASE의 재시도, OMG 표준화
4. **2016 No-Code/Low-Code** - 현재 진행 중인 트렌드

## 수정 계획

### Step 1: 표 확장
현재 8개 → 12개 항목으로 확장 (핵심 4개 추가)

```markdown
| 시대   | 기술                 | "개발자 필요 없다" 주장           | 실제 결과                            |
| ---- | ------------------ | ------------------------ | -------------------------------- |
| 1954 | FORTRAN            | 폰 노이만: "왜 기계어 이상이 필요한가?" | 고급 언어 혁명 시작, 생산성 45배 향상          |
| 1962 | COBOL              | "이제 누구나 코드를 작성할 수 있다"    | Grace Hopper: "소프트웨어 작성은 꽤 까다롭다" |
| 1972 | C                  | "프로그래머 더 이상 필요 없음"       | 생산성 향상, 프로그래머 수요 증가              |
| 1981 | 4GL                | "프로그래머 없는 개발" (James Martin) | 결국 프로그래머만 사용, RAD로 진화          |
| 1982 | CASE Tools         | "다이어그램→자동 코드 생성"         | 코드-모델 분기 문제로 실패                 |
| 1985 | C++                | "최종적 프로그래밍 언어"           | OOP 확산, 더 많은 프로젝트 창출             |
| 1992 | Visual Programming | "드래그 앤 드롭이 미래"           | 한계 노출, 코더 여전히 필수                |
| 2001 | MDA                | "모델만 그리면 코드 자동 생성"       | 부진, DSL로 진화                     |
| 2008 | Cloud              | "더 이상 엔지니어가 필요 없음"       | DevOps 탄생, 역할 확대                |
| 2010 | DevOps             | "누구나 인프라를 제어 가능"         | 전문 엔지니어 수요 급증                    |
| 2016 | No-Code/Low-Code   | "시민 개발자"                 | 진행 중, 여전히 IT 전문가 필요             |
| 2025 | GenAI              | "이번이야 진짜가 아닐까?"          | ???                              |
```

### Step 2: 관련 참고 문서 링크 추가
- `[[The-Recurring-Dream-of-Replacing-Developers]]` - Vault에서 발견한 핵심 문서

### Step 3: Jevons Paradox 설명 보강 (선택적)
각 시대별로 "개발자 대체" 예언이 실패한 이유를 Jevons Paradox로 연결

## 참고 자료

### Vault 내 관련 문서
- `/Users/msbaek/DocumentsLocal/msbaek_vault/003-RESOURCES/AI/LIMITATIONS/The-Recurring-Dream-of-Replacing-Developers.md`
- `/Users/msbaek/DocumentsLocal/msbaek_vault/003-RESOURCES/SEMINAR/AI-시대-개발자의-미래-뜬장의-시대/AI-시대-개발자의-미래-뜬장의-시대.md`

### 외부 참고
- The Ghost of CASE Tools (developmentcorporate.com)
- James Martin "Application Development Without Programmers" (1981)
- Martin Fowler's Bliki on MDA

## Backlog 태스크

| Task ID | 제목 | 우선순위 |
|---------|------|----------|
| task-5 | AI-문제점-종합-분석.md 개발자 대체 시도 역사 표 보완 | High |
| task-6 | CASE Tools 실패 분석 상세 섹션 추가 | Medium |
| task-7 | Jevons Paradox 설명 보강 | Low |
| task-8 | 관련 Vault 문서 링크 추가 | Low |

## 불확실성 맵

### 확실한 부분
- CASE, 4GL, MDA의 실패는 역사적으로 잘 문서화됨
- No-Code/Low-Code 트렌드는 현재 진행 중

### 불확실한 부분
- 각 기술의 정확한 등장 연도 (일부 출처마다 1-2년 차이)
  - 4GL: 1981 (James Martin 저서) vs 1980년대 초반
  - CASE: 1982 (Nastec) vs 1985 (시장 확산)

### 사용자 확인 완료
- ✅ 핵심 4개만 추가 (4GL, CASE, MDA, No-Code/Low-Code)
- ✅ 기존 Visual Programming과 별도 유지
