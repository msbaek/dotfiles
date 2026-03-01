# databricks-academy

> Databricks Academy 로그인 자동화 및 강의 콘텐츠 검색/추출 스킬

## 만든 배경

Databricks Academy(customer-academy.databricks.com)는 로그인이 필요한 사이트로, 강의 자료나 튜토리얼을 반복적으로 검색하고 추출하는 작업이 번거로웠습니다. 이 스킬은 Playwright MCP를 활용하여 로그인을 자동화하고, 강의 콘텐츠를 검색/추출하는 과정을 재사용 가능한 워크플로우로 추상화했습니다.

## 사용법

### 호출 방법

Databricks 관련 학습 자료나 강의를 검색할 때 자동으로 활성화됩니다.

**트리거 키워드:**
- "Databricks 강의", "Databricks 튜토리얼", "Databricks 인증"
- "Delta Lake 학습 자료", "MLflow 문서", "Unity Catalog 튜토리얼"
- "Databricks Academy에서 ... 찾아줘"

**명시적 호출:**
```
/databricks-academy
```

### 예시

**시나리오 1: Delta Lake 강의 검색**
```
사용자: Databricks Academy에서 Delta Lake 입문 강의 찾아줘
→ 스킬이 자동화된 로그인 수행
→ "Introduction to Delta Lake" 검색
→ 관련 강의 목록 및 URL 반환
```

**시나리오 2: SQL Analytics 학습 경로 탐색**
```
사용자: Databricks SQL 관련 hands-on lab 있어?
→ 로그인 후 "SQL Analytics hands-on lab" 검색
→ 실습 과정 목록 및 주요 토픽 요약 제공
```

## 주요 기능

- **자동 로그인**: Playwright MCP로 Databricks Academy 로그인 자동화 (이메일/비밀번호 입력 → 세션 유지)
- **강의 검색**: 키워드 기반 강의/튜토리얼/문서 검색, 최적화된 영문 검색어 자동 적용
- **콘텐츠 추출**: 강의 상세 페이지에서 syllabus, module, learning objectives 추출 및 요약
- **세션 관리**: 후속 질문을 위해 브라우저 세션 유지, 작업 종료 시 자동 종료 및 credential 폐기

## 의존성

| 도구/서비스 | 용도 |
|------------|------|
| Playwright MCP | 브라우저 자동화 (로그인, 페이지 네비게이션, 콘텐츠 추출) |
| Databricks Academy 계정 | customer-academy.databricks.com 로그인 인증 |
| `references/common_queries.md` | 검색 최적화를 위한 일반적인 쿼리 참고 자료 |

## 참고

- **보안**: 로그인 credential은 브라우저 세션 동안만 메모리에 유지되며 저장되지 않음
- **제한 사항**: 사용자 계정 권한 및 구독에 따라 접근 가능한 콘텐츠가 다를 수 있음
- **에러 처리**: 로그인 실패, 페이지 로드 타임아웃, 검색 결과 없음 등의 상황에 대한 자동 대응 포함
- **검색 최적화**: 결과가 없을 경우 자동으로 대체 키워드 제안 (예: "Delta Lake" → "Introduction to Delta Lake")
