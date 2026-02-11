# vis CLI 전체 레퍼런스

## 공통 옵션

모든 명령어에서 사용 가능한 공통 옵션:

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--data-dir` | 데이터 디렉토리 경로 | `~/git/vault-intelligence` |
| `--vault-path` | Vault 경로 | 설정 파일에서 읽음 |
| `--config` | 설정 파일 경로 | `config/settings.yaml` |
| `--verbose` | 상세 로그 출력 | off |

## search - 검색

시맨틱/키워드/하이브리드/ColBERT 검색.

### 기본 사용법
```bash
vis search --query "검색어"
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--query` | 검색 쿼리 (필수) | - |
| `--search-method` | semantic, keyword, hybrid, colbert | hybrid |
| `--top-k` | 반환 결과 수 | 10 |
| `--threshold` | 유사도 임계값 (0.0-1.0) | 0.3 |
| `--rerank` | 재순위화 활성화 | off |
| `--expand` | 쿼리 확장 (동의어 + HyDE) | off |
| `--no-synonyms` | 동의어 확장 비활성화 (--expand와 함께) | off |
| `--no-hyde` | HyDE 확장 비활성화 (--expand와 함께) | off |
| `--with-centrality` | 중심성 점수 반영 | off |
| `--centrality-weight` | 중심성 가중치 (0.0-1.0) | 0.2 |
| `--output` | 결과 파일 저장 (인자 없으면 기본 파일명) | - |

### 예제
```bash
# 기본 하이브리드 검색
vis search --query "TDD"

# 시맨틱 검색 + 재순위화
vis search --query "테스트 주도 개발" --search-method semantic --rerank

# 포괄적 검색 (쿼리 확장)
vis search --query "리팩토링" --expand --top-k 20

# 최고 품질 검색
vis search --query "클린코드" --rerank --expand --output results.md

# ColBERT 검색 (긴 문장, 복합 개념)
vis search --query "단위 테스트와 통합 테스트의 차이점" --search-method colbert

# 중심성 점수 반영
vis search --query "디자인 패턴" --with-centrality --centrality-weight 0.3
```

## collect - 주제별 문서 수집

특정 주제와 관련된 문서들을 수집하고 정리.

### 기본 사용법
```bash
vis collect --topic "주제" --output collection.md
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--topic` | 수집할 주제 (필수) | - |
| `--top-k` | 수집 문서 수 | 10 |
| `--threshold` | 유사도 임계값 | 0.3 |
| `--expand` | 쿼리 확장 | off |
| `--no-synonyms` | 동의어 비활성화 | off |
| `--no-hyde` | HyDE 비활성화 | off |
| `--output` | 출력 파일 | - |

### 예제
```bash
# 기본 수집
vis collect --topic "TDD" --output tdd-collection.md

# 포괄적 수집 (많은 문서 + 쿼리 확장)
vis collect --topic "클린코드" --top-k 30 --expand

# 높은 정확도로 수집
vis collect --topic "리팩토링" --threshold 0.5 --top-k 15
```

## related - 관련 문서 찾기

특정 문서와 유사한 관련 문서를 찾기.

### 기본 사용법
```bash
vis related --file "문서명.md"
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--file` | 기준 파일 (필수) | - |
| `--top-k` | 결과 수 | 10 |

### 예제
```bash
# 기본 사용
vis related --file "TDD-기초.md"

# 더 많은 관련 문서 찾기
vis related --file "디자인패턴-전략패턴.md" --top-k 20
```

## generate-moc - MOC 자동 생성

주제별 Map of Content를 자동으로 생성.

### 기본 사용법
```bash
vis generate-moc --topic "주제"
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--topic` | MOC 주제 (필수) | - |
| `--top-k` | 포함 문서 수 | 50 |
| `--output` | 출력 파일 | - |
| `--include-orphans` | 연결되지 않은 문서도 포함 | off |

### 예제
```bash
# 기본 MOC 생성
vis generate-moc --topic "TDD"

# 많은 문서 포함
vis generate-moc --topic "디자인패턴" --top-k 100

# 파일로 저장 + 고립 문서 포함
vis generate-moc --topic "클린코드" --output "MOC-클린코드.md" --include-orphans
```

## tag - 자동 태깅

문서에 hierarchical tag를 자동으로 부여.

### 기본 사용법
```bash
vis tag --target "문서명.md"
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--target` | 대상 파일 또는 폴더 (필수) | - |
| `--recursive` | 하위 폴더 포함 | off |
| `--dry-run` | 실제 변경 없이 미리보기 | off |
| `--tag-force` | 기존 태그 무시하고 재생성 | off |
| `--batch-size` | 배치 크기 | 10 |

### 예제
```bash
# 단일 문서 태깅
vis tag --target "문서명.md"

# 폴더 전체 태깅
vis tag --target "000-SLIPBOX/" --recursive

# 미리보기 (변경 사항 확인)
vis tag --target "문서명.md" --dry-run

# 기존 태그 무시하고 재생성
vis tag --target "문서명.md" --tag-force

# 배치 크기 조정
vis tag --target "폴더/" --recursive --batch-size 20
```

## add-related-docs - 관련 문서 섹션 추가

문서에 "관련 문서" 섹션을 자동으로 추가.

### 기본 사용법
```bash
vis add-related-docs --file "문서명.md"
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--file` | 대상 파일 | - |
| `--batch` | 배치 처리 모드 | off |
| `--pattern` | 배치 파일 패턴 (예: '*.md') | - |
| `--dry-run` | 미리보기 | off |
| `--backup` | 원본 백업 | off |
| `--update-existing` | 기존 섹션 업데이트 | off |
| `--no-update-existing` | 기존 섹션 있으면 스킵 | off |
| `--format-style` | simple 또는 detailed | - |
| `--similarity-threshold` | 유사도 임계값 | 0.3 |
| `--top-k` | 관련 문서 수 | 10 |

### 예제
```bash
# 기본 사용
vis add-related-docs --file "문서명.md"

# 미리보기
vis add-related-docs --file "문서명.md" --dry-run

# 배치 처리
vis add-related-docs --batch --pattern "000-SLIPBOX/*.md"

# 원본 백업 + 기존 섹션 업데이트
vis add-related-docs --file "문서명.md" --backup --update-existing

# 더 많은 관련 문서 + 높은 유사도
vis add-related-docs --file "문서명.md" --top-k 15 --similarity-threshold 0.5
```

## analyze-gaps - 지식 공백 분석

vault에서 부족한 주제나 연결이 약한 영역을 분석.

### 기본 사용법
```bash
vis analyze-gaps
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--top-k` | 분석 결과 수 | 20 |
| `--min-connections` | 최소 연결 수 (이하면 약한 연결) | 2 |

### 예제
```bash
# 기본 분석
vis analyze-gaps

# 더 많은 결과
vis analyze-gaps --top-k 50

# 연결 임계값 조정
vis analyze-gaps --min-connections 3
```

## duplicates - 중복 감지

내용이 유사한 중복 문서를 찾아 정리.

### 기본 사용법
```bash
vis duplicates
```

### 옵션

옵션 없음. 기본 실행.

### 예제
```bash
# 중복 문서 감지
vis duplicates
```

## analyze - 주제 분석

vault 전체의 주제 분포를 분석.

### 기본 사용법
```bash
vis analyze
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--output` | 출력 파일 | - |

### 예제
```bash
# 기본 분석
vis analyze

# 파일로 저장
vis analyze --output analysis.md
```

## summarize - 클러스터 요약

문서를 클러스터링하고 주제별로 요약.

### 기본 사용법
```bash
vis summarize
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--clusters` | 클러스터 수 (미지정 시 자동 결정) | auto |
| `--algorithm` | kmeans, dbscan, agglomerative | 설정파일 |
| `--style` | brief, detailed, technical, conceptual | detailed |
| `--topic` | 특정 주제 필터 | - |
| `--since` | 특정 날짜 이후만 (YYYY-MM-DD) | - |
| `--max-docs` | 클러스터별 최대 문서 수 | - |
| `--output` | 출력 파일 | - |

### 예제
```bash
# 기본 요약 (자동 클러스터 결정)
vis summarize

# 클러스터 수 지정
vis summarize --clusters 5

# 특정 주제 필터링
vis summarize --topic "TDD" --clusters 3 --style detailed

# 최근 문서만
vis summarize --since "2024-01-01" --output recent.md

# 알고리즘 선택
vis summarize --algorithm dbscan --style technical
```

## review - 학습 리뷰

일정 기간의 학습 활동을 리뷰.

### 기본 사용법
```bash
vis review --period weekly
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--period` | weekly, monthly, quarterly | weekly |
| `--from` | 시작 날짜 (YYYY-MM-DD) | - |
| `--to` | 종료 날짜 (YYYY-MM-DD) | - |
| `--topic` | 특정 주제 필터 | - |
| `--output` | 출력 파일 | - |

### 예제
```bash
# 주간 리뷰
vis review --period weekly

# 월간 리뷰
vis review --period monthly --output monthly-review.md

# 커스텀 기간
vis review --from 2024-08-01 --to 2024-08-31

# 특정 주제만
vis review --topic TDD --period quarterly
```

## clean-tags - 고립 태그 정리

1개 이하 문서에서만 사용되는 고립 태그를 감지하고 정리.

### 기본 사용법
```bash
vis clean-tags
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--dry-run` | 미리보기 | off |

### 예제
```bash
# 고립 태그 감지만
vis clean-tags

# 미리보기 (변경 사항 확인)
vis clean-tags --dry-run
```

## reindex - 인덱스 재구축

새 문서 추가 후 또는 인덱스 갱신이 필요할 때.

### 기본 사용법
```bash
vis reindex
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--force` | 강제 전체 재인덱싱 | off |
| `--with-colbert` | ColBERT 인덱싱 포함 | off |
| `--colbert-only` | ColBERT만 재인덱싱 | off |
| `--sample-size` | 샘플링 문서 수 | - |
| `--include-folders` | 포함할 폴더 목록 | - |
| `--exclude-folders` | 제외할 폴더 목록 | - |

### 예제
```bash
# 기본 재인덱싱 (변경된 문서만)
vis reindex

# ColBERT 포함
vis reindex --with-colbert

# 강제 전체 재인덱싱
vis reindex --force

# 특정 폴더만
vis reindex --include-folders 000-SLIPBOX 003-RESOURCES

# ColBERT만 재인덱싱
vis reindex --colbert-only

# 샘플링 테스트
vis reindex --sample-size 100
```

## init - 시스템 초기화

최초 설정 시 시스템을 초기화.

### 기본 사용법
```bash
vis init --vault-path /path/to/vault
```

### 옵션

| 옵션 | 설명 | 기본값 |
|---|---|---|
| `--vault-path` | Vault 경로 (필수) | - |

### 예제
```bash
# 시스템 초기화
vis init --vault-path ~/Documents/MyVault
```

## test - 시스템 테스트

엔진, 캐시, 프로세서 등 전체 시스템을 테스트.

### 기본 사용법
```bash
vis test
```

### 옵션

옵션 없음. 전체 시스템 테스트 실행.

### 예제
```bash
# 시스템 테스트
vis test
```

## info - 시스템 정보

캐시 상태, 모델 정보, 기능 목록 표시.

### 기본 사용법
```bash
vis info
```

### 옵션

옵션 없음. 시스템 상태 정보 출력.

### 예제
```bash
# 시스템 정보 확인
vis info
```

## 검색 방법 선택 가이드

| 검색 방법 | 사용 상황 | 속도 | 정확도 |
|-----------|-----------|------|--------|
| `semantic` | 개념적, 의미적 검색 | ⚡⚡⚡ | ⭐⭐⭐ |
| `keyword` | 정확한 용어 검색 | ⚡⚡⚡ | ⭐⭐ |
| `hybrid` | 일반적인 모든 검색 (권장) | ⚡⚡⚡ | ⭐⭐⭐⭐ |
| `colbert` | 긴 문장, 복합 개념 | ⚡⚡ | ⭐⭐⭐⭐ |
| `--rerank` | 고정확도 필요 시 | ⚡⚡ | ⭐⭐⭐⭐⭐ |
| `--expand` | 포괄적 검색 필요 시 | ⚡ | ⭐⭐⭐⭐ |

## 클러스터링 알고리즘 선택 가이드

| 알고리즘 | 사용 상황 | 특징 |
|----------|-----------|------|
| `kmeans` | 클러스터 수를 알 때 | 빠르고 안정적, 구형 클러스터 |
| `dbscan` | 밀도 기반 클러스터링 | 잡음 제거, 임의 형태 클러스터 |
| `agglomerative` | 계층적 구조 필요 시 | 트리 구조, 유연한 클러스터 수 |

## 요약 스타일 선택 가이드

| 스타일 | 설명 | 사용 상황 |
|--------|------|-----------|
| `brief` | 간단한 요약 | 빠른 개요 파악 |
| `detailed` | 상세한 요약 | 완전한 이해 필요 |
| `technical` | 기술적 요약 | 개발자, 기술 문서 |
| `conceptual` | 개념적 요약 | 학습, 교육 자료 |

## 자주 실수하는 옵션

| 잘못된 옵션 | 올바른 옵션 | 비고 |
|---|---|---|
| `--method` | `--search-method` | 검색 방법 지정 |
| `--k` | `--top-k` | 결과 수 지정 |
| `--top` | `--top-k` | 결과 수 지정 |
| `--output-file` | `--output` | 출력 파일 지정 |
| `--reranking` | `--rerank` | 재순위화 활성화 |
| `--synonym` | `--no-synonyms` | 동의어 비활성화 |

## 성능 최적화 팁

1. **일반 검색**: `--search-method hybrid` (기본값, 빠르고 정확)
2. **고정확도 검색**: `--rerank` 추가 (약간 느려지지만 훨씬 정확)
3. **포괄적 검색**: `--expand` 추가 (더 많은 결과)
4. **빠른 검색**: `--search-method keyword` (가장 빠름)
5. **복합 쿼리**: `--search-method colbert` (긴 문장, 복잡한 질문)

## 일반적인 워크플로우

### 새 주제 학습 시작
```bash
# 1. 관련 문서 검색
vis search --query "새로운 주제" --rerank --expand

# 2. 주제별 문서 수집
vis collect --topic "새로운 주제" --output collection.md

# 3. MOC 생성
vis generate-moc --topic "새로운 주제" --output "MOC-새로운주제.md"
```

### 문서 정리 및 연결
```bash
# 1. 자동 태깅
vis tag --target "000-SLIPBOX/" --recursive

# 2. 관련 문서 링크 추가
vis add-related-docs --batch --pattern "000-SLIPBOX/*.md"

# 3. 중복 문서 확인
vis duplicates

# 4. 고립 태그 정리
vis clean-tags
```

### 주기적 리뷰
```bash
# 1. 주간 리뷰
vis review --period weekly --output weekly-review.md

# 2. 지식 공백 분석
vis analyze-gaps --top-k 20

# 3. 주제 분포 확인
vis analyze --output analysis.md
```
