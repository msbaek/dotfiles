# vis

> Obsidian vault를 위한 AI 기반 지능형 검색 및 지식 관리 skill

## 만든 배경

vault-intelligence CLI의 19개 명령어를 Claude Code에서 자연어로 호출할 수 있도록 2026-02-11에 구현했습니다.
사용자의 의도("TDD 자료 찾아줘", "이 문서 태깅해줘")를 분석하여 적절한 검색 방법과 명령어를 자동 선택하고, 검색 옵션까지 지능적으로 조합합니다.

## 사용법

### 호출 방법

```bash
/vis "검색어 또는 요청"
```

또는 대화 중 vault 검색/태깅/MOC 생성/관련 문서 찾기 등의 의도를 표현하면 자동 적용됩니다.

### 예시

```bash
# 검색
/vis "TDD 관련 문서 찾아줘"              → vis search "TDD" --rerank
/vis "리팩토링에 대해 깊이 있게 검색"     → vis search "리팩토링" --rerank --expand

# 문서 정리
/vis "클린코드 자료 모아줘"               → vis collect "클린코드" --output collection.md
/vis "이 문서와 비슷한 거 찾아줘"         → vis related "문서명.md"

# 태그/MOC
/vis "이 문서 태깅해줘"                   → vis tag "문서명.md"
/vis "TDD MOC 만들어줘"                  → vis generate-moc "TDD"

# 분석
/vis "vault 빈 부분 뭐야?"                → vis analyze-gaps
/vis "중복 문서 있어?"                    → vis duplicates
/vis "이번 주 학습 정리해줘"              → vis review --period weekly
```

## 주요 기능

### 1. 검색 (search)
- **4가지 검색 방법**: semantic(의미), keyword(키워드), hybrid(혼합), colbert(긴 문장)
- **자동 방법 선택**: 사용자의 표현을 분석하여 최적 검색 방법 자동 선택
  - "정확히", "~라는 단어" → keyword
  - "~에 대해", "~란 무엇" → semantic
  - 긴 문장/복합 개념 → colbert
  - 일반적인 검색 → hybrid (기본)
- **품질 옵션 자동 추가**: "정확한" → `--rerank`, "빠짐없이" → `--expand`
- **BGE-M3 모델 기반** 시맨틱 검색 엔진

### 2. 문서 정리
- **collect**: 주제별 문서 수집 및 정리
- **related**: 특정 문서와 유사한 관련 문서 찾기
- **generate-moc**: 주제별 Map of Content 자동 생성
- **add-related-docs**: 문서에 "관련 문서" 섹션 자동 추가
- **connect-topic**: MOC 생성 + 관련 문서 링크 삽입을 한 번에 처리

### 3. 태깅 및 정리
- **tag**: hierarchical tag 자동 부여 (단일 문서 또는 폴더 전체)
- **clean-tags**: 고립 태그 감지 및 정리
- **list-tags**: 태그 목록 및 사용 통계 확인

### 4. 분석 및 리뷰
- **analyze-gaps**: vault의 지식 공백 분석
- **duplicates**: 중복/유사 문서 감지
- **analyze**: vault 주제 분포 분석
- **summarize**: 문서 클러스터링 및 주제별 요약
- **review**: 기간별 학습 활동 리뷰 (주간/월간/분기)

### 5. 시스템 관리
- **reindex**: 검색 인덱스 재구축 (새 문서 추가 후)
- **info**: 시스템 상태 및 캐시 정보 확인
- **connect-status**: 주제별 문서 연결 진행 상황 확인

## 검색 전략 자동 선택 규칙

| 사용자 표현 | 검색 옵션 |
|---|---|
| "정확한", "가장 관련 높은" | `--rerank` 추가 (재순위화) |
| "다 찾아줘", "빠짐없이", "포괄적으로" | `--expand` 추가 (쿼리 확장) |
| "완전히", "깊이 있게", "철저하게" | `--rerank --expand` 둘 다 추가 |
| "정확히 ~라는 단어" | `--search-method keyword` |
| "~에 대해", "~란 무엇" | `--search-method semantic` |
| 긴 문장, 복합 개념 | `--search-method colbert` |
| 일반 검색 | `--search-method hybrid` (기본) |

## 의존성

- **vault-intelligence CLI**: BGE-M3 기반 검색 엔진
  - 설치 경로: `~/git/vault-intelligence`
  - Python 3.10+ 필요
- **Obsidian vault**: `$VAULT_ROOT` 환경변수로 지정된 vault
- **설정 파일**: `~/git/vault-intelligence/config/settings.yaml`

## 자주 실수하는 옵션

| 잘못된 옵션 | 올바른 옵션 |
|---|---|
| `--method` | `--search-method` |
| `--k`, `--top` | `--top-k` |
| `--output-file` | `--output` |
| `--reranking` | `--rerank` |
| `--query "TDD"` | positional 인자: `vis search "TDD"` |

## 참고

- **SKILL.md**: 전체 명령어 매핑 및 옵션 상세 설명
- **references/cli-reference.md**: 19개 명령어 전체 CLI 레퍼런스
- **vault-intelligence 프로젝트**: [GitHub](https://github.com/yourusername/vault-intelligence) (경로 확인 필요)
