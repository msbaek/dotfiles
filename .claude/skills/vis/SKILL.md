---
name: vis
description: |
  Vault Intelligence System (vis) CLI를 활용한 Obsidian vault 시맨틱 검색, 자동 태깅,
  MOC 생성, 관련 문서 연결, 주제 수집, 지식 공백 분석, 중복 감지, 학습 리뷰 등
  vault 지식 관리 전반을 지원하는 skill.
  vault 검색, 문서 정리, 태그, MOC, 관련 문서, 주제 수집, 중복 검사, 학습 리뷰,
  지식 공백, 클러스터링, 인덱싱 관련 작업 시 자동 적용.
---

# Vault Intelligence System (vis) Skill

## 개요

vis는 BGE-M3 기반 시맨틱 검색 엔진으로 Obsidian vault의 지식 관리를 지원하는 CLI 도구.
사용자의 요청을 분석하여 최적의 vis 명령어와 옵션을 자동 선택하여 실행.

## 사용자 의도 → vis 명령어 매핑

사용자가 아래 의도를 표현하면 해당 vis 명령어를 적극 제안하고 실행.

| 사용자 의도 | vis 명령어 | 예시 요청 |
|---|---|---|
| 문서 검색 | `vis search` | "TDD 관련 문서 찾아줘", "리팩토링에 대해 검색해줘" |
| 주제별 문서 수집 | `vis collect` | "TDD 관련 자료 모아줘", "클린코드 문서 정리해줘" |
| 관련 문서 찾기 | `vis related` | "이 문서와 비슷한 거 찾아줘", "연관 문서 뭐 있어?" |
| MOC 생성 | `vis generate-moc` | "TDD MOC 만들어줘", "주제별 목차 생성해줘" |
| 자동 태깅 | `vis tag` | "이 문서에 태그 달아줘", "폴더 전체 태깅해줘" |
| 관련 문서 섹션 추가 | `vis add-related-docs` | "관련 문서 링크 넣어줘", "백링크 추가해줘" |
| 지식 공백 분석 | `vis analyze-gaps` | "vault에 빈 부분 뭐야?", "부족한 주제 찾아줘" |
| 중복 문서 감지 | `vis duplicates` | "중복 문서 있어?", "겹치는 내용 찾아줘" |
| 주제 분석 | `vis analyze` | "vault 주제 분포 보여줘", "어떤 주제가 많아?" |
| 클러스터 요약 | `vis summarize` | "문서 클러스터링해줘", "주제별로 묶어줘" |
| 학습 리뷰 | `vis review` | "이번 주 학습 정리해줘", "월간 리뷰 만들어줘" |
| 고립 태그 정리 | `vis clean-tags` | "안 쓰는 태그 정리해줘", "태그 정리" |
| 인덱스 갱신 | `vis reindex` | "인덱스 다시 만들어줘", "새 문서 반영해줘" |
| 시스템 상태 확인 | `vis info` | "vis 상태 어때?", "캐시 상태 확인" |

## 검색 전략 자동 선택

`vis search` 실행 시, 사용자의 표현을 분석하여 최적의 옵션을 자동 조합.

### 검색 방법 선택 기준

| 판단 기준 | 검색 방법 | 옵션 |
|---|---|---|
| 정확한 용어/키워드 검색 ("~라는 단어", "정확히") | keyword | `--search-method keyword` |
| 개념/의미 기반 탐색 ("~에 대해", "~란 무엇") | semantic | `--search-method semantic` |
| 일반적인 검색 (기본) | hybrid | `--search-method hybrid` |
| 긴 문장, 복합 개념, 여러 주제 결합 | colbert | `--search-method colbert` |

### 품질 옵션 자동 추가 기준

| 사용자 표현 키워드 | 추가 옵션 | 효과 |
|---|---|---|
| "정확한", "가장 관련 높은", "best" | `--rerank` | 재순위화로 정확도 향상 |
| "다 찾아줘", "빠짐없이", "포괄적으로" | `--expand` | 동의어 + HyDE 확장 |
| "완전히", "깊이 있게", "철저하게" | `--rerank --expand` | 최고 품질 검색 |
| 결과가 부족할 때 | `--top-k 20` | 더 많은 결과 반환 |
| 최근 문서만 | `--threshold 0.5` | 높은 유사도만 |

### 검색 실행 기본 패턴

```bash
# 기본 검색
vis search --query "검색어"

# 고품질 검색 (정확도 중요)
vis search --query "검색어" --rerank

# 포괄적 검색 (놓치지 않기)
vis search --query "검색어" --expand

# 최고 품질 (정확 + 포괄)
vis search --query "검색어" --rerank --expand

# 결과 저장
vis search --query "검색어" --output results.md
```

## 주요 명령어 사용 패턴

### 주제별 문서 수집 (collect)
사용자가 특정 주제의 문서를 모으려 할 때 사용.
```bash
vis collect --topic "주제" --output collection.md
vis collect --topic "주제" --top-k 30 --expand    # 포괄적 수집
```

### 관련 문서 찾기 (related)
특정 문서와 유사한 문서를 찾을 때 사용.
```bash
vis related --file "문서명.md" --top-k 10
```

### MOC 자동 생성 (generate-moc)
주제별 Map of Content를 자동으로 생성할 때 사용.
```bash
vis generate-moc --topic "주제" --top-k 50
vis generate-moc --topic "주제" --output "MOC-주제.md" --include-orphans
```

### 자동 태깅 (tag)
문서에 hierarchical tag를 자동으로 부여.
```bash
vis tag --target "문서명.md"                    # 단일 문서
vis tag --target "폴더명/" --recursive          # 폴더 전체
vis tag --target "문서명.md" --dry-run          # 미리보기
vis tag --target "문서명.md" --tag-force        # 기존 태그 무시하고 재생성
```

### 관련 문서 섹션 추가 (add-related-docs)
문서에 "관련 문서" 섹션을 자동으로 추가.
```bash
vis add-related-docs --file "문서명.md"
vis add-related-docs --file "문서명.md" --dry-run           # 미리보기
vis add-related-docs --batch --pattern "000-SLIPBOX/*.md"   # 배치 처리
```

### 지식 공백 분석 (analyze-gaps)
vault에서 부족한 주제나 연결이 약한 영역을 분석.
```bash
vis analyze-gaps --top-k 20
```

### 중복 문서 감지 (duplicates)
내용이 유사한 중복 문서를 찾아 정리.
```bash
vis duplicates
```

### 주제 분석 (analyze)
vault 전체의 주제 분포를 분석.
```bash
vis analyze --output analysis.md
```

### 클러스터 요약 (summarize)
문서를 클러스터링하고 주제별로 요약.
```bash
vis summarize --clusters 5
vis summarize --topic "TDD" --clusters 3 --style detailed
vis summarize --since "2024-01-01" --output recent.md
```

### 학습 리뷰 (review)
일정 기간의 학습 활동을 리뷰.
```bash
vis review --period weekly
vis review --period monthly --output monthly-review.md
vis review --from 2024-08-01 --to 2024-08-31
vis review --topic TDD --period quarterly
```

### 고립 태그 정리 (clean-tags)
1개 이하 문서에서만 사용되는 고립 태그를 감지하고 정리.
```bash
vis clean-tags                  # 감지만
vis clean-tags --dry-run        # 미리보기
```

### 인덱스 관리 (reindex)
새 문서 추가 후 또는 인덱스 갱신이 필요할 때.
```bash
vis reindex                       # 기본 재인덱싱
vis reindex --with-colbert        # ColBERT 포함
vis reindex --force               # 강제 전체 재인덱싱
vis reindex --include-folders 000-SLIPBOX 003-RESOURCES   # 특정 폴더만
```

## vis 기능 전체 안내

사용자가 "vis로 뭘 할 수 있어?", "vis 기능 알려줘" 등으로 질문하면 아래 내용을 기반으로 상세히 안내.

### 16개 명령어 전체 목록

1. **search** - 시맨틱/키워드/하이브리드/ColBERT 검색 (4가지 방법 + rerank + expand)
2. **collect** - 주제별 문서 수집 및 정리
3. **related** - 특정 문서와 유사한 관련 문서 찾기
4. **generate-moc** - 주제별 Map of Content 자동 생성
5. **tag** - 문서에 hierarchical tag 자동 부여
6. **add-related-docs** - 문서에 "관련 문서" 섹션 자동 추가
7. **analyze-gaps** - vault의 지식 공백 분석
8. **duplicates** - 중복/유사 문서 감지
9. **analyze** - vault 주제 분포 분석
10. **summarize** - 문서 클러스터링 및 주제별 요약
11. **review** - 기간별 학습 활동 리뷰 (주간/월간/분기)
12. **clean-tags** - 고립 태그 감지 및 정리
13. **reindex** - 검색 인덱스 재구축
14. **init** - 시스템 초기화 (최초 설정)
15. **test** - 시스템 테스트
16. **info** - 시스템 상태 및 캐시 정보 확인

### 검색 엔진 특징
- BGE-M3 모델 기반 Dense + Sparse + ColBERT 3가지 임베딩
- Cross-encoder 재순위화 (BGE Reranker V2-M3)
- 쿼리 확장: 동의어 + HyDE (Hypothetical Document Embedding)
- SQLite 캐싱으로 빠른 반복 검색

## 자주 실수하는 옵션

| 잘못된 옵션 | 올바른 옵션 |
|---|---|
| `--method` | `--search-method` |
| `--k` | `--top-k` |
| `--top` | `--top-k` |
| `--output-file` | `--output` |
| `--reranking` | `--rerank` |

상세 CLI 레퍼런스는 `references/cli-reference.md` 참조.
