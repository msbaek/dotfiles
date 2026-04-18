---
argument-hint: "[검색어 또는 명령어]"
description: "Vault Intelligence System을 활용한 Obsidian vault 지능형 검색 및 분석"
color: cyan
model: haiku
---

# Vault Intelligence 검색 - $ARGUMENTS

vault-intelligence 시스템을 활용하여 Obsidian vault 문서를 검색하고 분석합니다.

## 🎯 사용 방법 (간단!)

### 방법 1: 검색어만 입력 (가장 간단, 권장)

```bash
/obsidian:vault-query "TDD"
/obsidian:vault-query "리팩토링 기법"
/obsidian:vault-query "clean architecture"
```

→ **검색어만 입력하면 대화형으로 필요한 옵션을 물어봅니다!**

### 방법 2: 인자 없이 실행 (대화형 모드)

```bash
/obsidian:vault-query
```

→ 무엇을 하고 싶은지 물어보고 단계별로 안내합니다.

### 방법 3: 고급 사용자 (옵션 직접 지정)

```bash
/obsidian:vault-query "TDD" --method hybrid --rerank
```

→ 옵션을 알고 있다면 직접 지정 가능

## 시스템 위치

- **vault-intelligence 경로**: `~/git/vault-intelligence/`
- **vault 경로**: `$VAULT_ROOT/`

## 작업 프로세스

### 1. 인자 분석

**Case 1: 인자가 없는 경우**
- 대화형 메뉴 표시
- 사용자가 원하는 작업 선택
- 필요한 정보를 단계별로 질문

**Case 2: 검색어만 있는 경우**
- 기본 검색 수행 (hybrid 방식)
- 결과 표시 후 추가 옵션 제안
- 사용자가 선택하면 추가 검색 실행

**Case 3: 검색어 + 옵션이 있는 경우**
- 지정된 옵션으로 즉시 검색 실행

### 2. 대화형 질문 예시

```
🔍 Vault Intelligence에 오신 것을 환영합니다!

무엇을 하시겠습니까?

1️⃣ 문서 검색 (기본)
2️⃣ 관련 문서 찾기
3️⃣ MOC 생성
4️⃣ 주제별 문서 수집
5️⃣ 지식 공백 분석
6️⃣ 고급 검색 옵션 설정

선택 (1-6): _
```

**검색어 입력 후:**
```
검색어: "TDD"

어떤 방식으로 검색하시겠습니까?

1️⃣ 빠르고 정확한 검색 (추천) - hybrid 방식
2️⃣ 의미 중심 검색 - 관련 개념도 함께 검색
3️⃣ 정확한 키워드 검색 - 입력한 단어가 포함된 문서만
4️⃣ 정밀 검색 (느림) - 긴 문장에 최적화

선택 (1-4, 엔터=1): _
```

**결과 표시 후:**
```
📊 검색 결과 5개를 찾았습니다.

추가로 하시겠습니까?

1️⃣ 결과를 파일로 저장
2️⃣ 더 정확한 결과 보기 (재순위화)
3️⃣ 관련 개념도 함께 검색 (쿼리 확장)
4️⃣ 더 많은 결과 보기 (20개)
5️⃣ 관련 문서 찾기
6️⃣ 이 주제로 MOC 생성
0️⃣ 완료

선택 (0-6): _
```

### 3. 검색 실행

```bash
cd ~/git/vault-intelligence
python -m src search --query "검색어" [옵션들...]
```

### 4. 결과 표시

- 검색 결과를 사용자 친화적 형식으로 출력
- 다음 단계 추천 제공
- 추가 작업 옵션 제시

## 주요 기능

### 1. 지능형 검색

#### 기본 검색 방법

- **semantic**: 의미적 검색 (개념 기반)
  ```bash
  python -m src search --query "검색어" --search-method semantic
  ```

- **keyword**: 키워드 검색 (정확한 매칭)
  ```bash
  python -m src search --query "검색어" --search-method keyword
  ```

- **hybrid**: 하이브리드 검색 (기본값, 권장)
  ```bash
  python -m src search --query "검색어" --search-method hybrid
  ```

- **colbert**: ColBERT 토큰 검색 (정밀 매칭, 긴 문장에 최적화)
  ```bash
  python -m src search --query "검색어" --search-method colbert
  ```

#### 고급 옵션

- **--rerank**: 재순위화로 정확도 15-25% 향상 (처리 시간 2-3배)
  ```bash
  python -m src search --query "검색어" --rerank
  ```

- **--expand**: 쿼리 확장 (동의어 + HyDE)
  ```bash
  python -m src search --query "검색어" --expand
  python -m src search --query "검색어" --expand --no-hyde      # 동의어만
  python -m src search --query "검색어" --expand --no-synonyms  # HyDE만
  ```

- **--top-k N**: 결과 수 지정 (기본값: 10)
  ```bash
  python -m src search --query "검색어" --top-k 20
  ```

- **--threshold N**: 유사도 임계값 (기본값: 0.3)
  ```bash
  python -m src search --query "검색어" --threshold 0.5
  ```

- **--with-centrality**: 중심성 점수 반영
  ```bash
  python -m src search --query "검색어" --with-centrality
  ```

- **--output [파일명]**: 결과를 파일로 저장
  ```bash
  python -m src search --query "검색어" --output results.md
  python -m src search --query "검색어" --output  # 기본 파일명
  ```

### 2. 관련 문서 찾기

```bash
python -m src related --file "문서명.md" --top-k 10
```

### 3. 지식 공백 분석

```bash
python -m src analyze-gaps --top-k 20
```

### 4. 주제별 문서 수집

```bash
python -m src collect --topic "주제명" --output collection.md
```

### 5. MOC 자동 생성

```bash
python -m src generate-moc --topic "주제명" --top-k 50
```

### 6. 자동 태깅

```bash
# 단일 파일
python -m src tag "문서명.md"

# 디렉토리 전체 (재귀)
python -m src tag "폴더명/" --recursive
```

### 7. 시스템 관리

```bash
# 인덱스 재구축
python -m src reindex                    # 기본
python -m src reindex --with-colbert     # ColBERT 포함
python -m src reindex --force            # 강제 전체 재인덱싱

# 시스템 정보
python -m src info
```

## 검색 방법 선택 가이드

| 검색 방법 | 사용 상황 | 속도 | 정확도 | 예시 |
|-----------|-----------|------|--------|------|
| `semantic` | 개념적, 의미적 검색 | ⚡⚡⚡ | ⭐⭐⭐ | "객체지향 설계 원칙" |
| `keyword` | 정확한 용어 검색 | ⚡⚡⚡ | ⭐⭐ | "SOLID", "DDD" |
| `hybrid` | 일반적인 모든 검색 (권장) | ⚡⚡⚡ | ⭐⭐⭐⭐ | "TDD 실무 적용" |
| `colbert` | 긴 문장, 복합 개념 | ⚡⚡ | ⭐⭐⭐⭐ | "test driven development refactoring practices" |
| `--rerank` | 고정확도 필요 시 | ⚡⚡ | ⭐⭐⭐⭐⭐ | 최종 결과 정제 |
| `--expand` | 포괄적 검색 필요 시 | ⚡ | ⭐⭐⭐⭐ | 관련 개념 모두 찾기 |

## 사용 예시 (실제 시나리오)

### 시나리오 1: 처음 사용하는 경우

```bash
/obsidian:vault-query
```

**대화 흐름:**
```
🔍 Vault Intelligence에 오신 것을 환영합니다!

무엇을 하시겠습니까?
□ 문서 검색 - 키워드로 vault 문서 검색
□ 관련 문서 찾기 - 특정 문서와 유사한 문서 찾기
□ MOC 생성 - 주제별 Map of Content 자동 생성
□ 주제별 수집 - 특정 주제의 모든 문서 수집
□ 지식 공백 분석 - 학습이 부족한 영역 발견

→ "문서 검색" 선택
→ 검색어 입력: "TDD"
→ 검색 실행 및 결과 표시
→ 추가 옵션 제시...
```

### 시나리오 2: 빠른 검색 (가장 많이 사용)

```bash
/obsidian:vault-query "리팩토링 기법"
```

**자동으로:**
- hybrid 방식으로 검색
- 상위 5개 결과 표시
- 추가 옵션 제시 (더 정확하게/더 많이/MOC 생성 등)

### 시나리오 3: 고급 사용자 (옵션 알고 있는 경우)

```bash
/obsidian:vault-query "clean architecture" --method hybrid --rerank
```

**즉시:**
- 지정된 옵션으로 검색 실행
- 결과만 표시 (추가 질문 없음)

### 시나리오 4: 대화형으로 진행

```bash
/obsidian:vault-query "DDD"
```

**흐름:**
```
📊 검색 결과 5개를 찾았습니다.

1. Domain-Driven Design 핵심 개념 (0.85)
2. DDD 전략적 설계 (0.78)
...

검색 결과가 만족스러우신가요? 추가 작업을 선택하세요.
□ 완료 - 검색 종료
□ 더 정확하게 - 재순위화로 정확도 향상 (느림)
□ 더 많이 - 결과 20개로 확대
□ 더 포괄적으로 - 관련 개념도 함께 검색
□ 관련 문서 - 첫 번째 결과의 관련 문서 찾기
□ MOC 생성 - 이 주제로 Map of Content 생성

→ "MOC 생성" 선택
→ 문서 수 선택 (20/50/100)
→ MOC 자동 생성...
```

## 실행 로직 (대화형 모드)

### 핵심 원칙: **사용자에게 질문하고 선택하게 하기**

AskUserQuestion 도구를 적극 활용하여 옵션을 외우지 않아도 되게 만드세요!

### 1. 인자가 없는 경우: 전체 메뉴

```python
# 의사 코드
if not $ARGUMENTS:
    response = ask_user_question(
        question="무엇을 하시겠습니까?",
        header="작업 선택",
        options=[
            {label: "문서 검색", description: "키워드로 vault 문서 검색"},
            {label: "관련 문서 찾기", description: "특정 문서와 유사한 문서 찾기"},
            {label: "MOC 생성", description: "주제별 Map of Content 자동 생성"},
            {label: "주제별 수집", description: "특정 주제의 모든 문서 수집"},
            {label: "지식 공백 분석", description: "학습이 부족한 영역 발견"}
        ]
    )

    # 선택에 따라 추가 질문
    if response == "문서 검색":
        query = ask_text("검색어를 입력하세요:")
        proceed_with_search(query)
    elif response == "관련 문서 찾기":
        # 파일 선택 로직...
```

### 2. 검색어만 있는 경우: 검색 방법 선택

```python
if has_query_only($ARGUMENTS):
    query = extract_query($ARGUMENTS)

    # 먼저 기본 검색 수행
    execute_search(query, method="hybrid", top_k=5)

    # 결과 표시 후 추가 옵션 제안
    response = ask_user_question(
        question="검색 결과가 만족스러우신가요? 추가 작업을 선택하세요.",
        header="다음 단계",
        multiSelect=false,
        options=[
            {label: "완료", description: "검색 종료"},
            {label: "더 정확하게", description: "재순위화로 정확도 15-25% 향상 (느림)"},
            {label: "더 많이", description: "결과 20개로 확대"},
            {label: "더 포괄적으로", description: "관련 개념도 함께 검색 (쿼리 확장)"},
            {label: "관련 문서", description: "첫 번째 결과의 관련 문서 찾기"},
            {label: "MOC 생성", description: "이 주제로 Map of Content 생성"},
            {label: "파일 저장", description: "결과를 마크다운 파일로 저장"}
        ]
    )

    # 선택에 따라 추가 검색
    if response == "더 정확하게":
        execute_search(query, method="hybrid", rerank=true, top_k=5)
    elif response == "더 많이":
        execute_search(query, method="hybrid", top_k=20)
    # ... 기타 옵션 처리
```

### 3. 검색어 + 옵션: 즉시 실행

```python
if has_query_and_options($ARGUMENTS):
    # 옵션 파싱
    query = extract_query($ARGUMENTS)
    method = extract_method($ARGUMENTS) or "hybrid"
    rerank = "--rerank" in $ARGUMENTS
    expand = "--expand" in $ARGUMENTS
    top_k = extract_value("--top-k", $ARGUMENTS) or 10

    # 즉시 실행
    cmd = build_command(query, method, rerank, expand, top_k)
    execute(cmd)
    display_results()
```

### 4. 특수 기능: 간단한 질문으로 안내

```python
# MOC 생성 요청
if user_wants_moc:
    topic = ask_text("어떤 주제의 MOC를 생성하시겠습니까?")

    response = ask_user_question(
        question="몇 개의 문서를 포함하시겠습니까?",
        header="문서 수",
        options=[
            {label: "20개", description: "핵심 문서만 (빠름)"},
            {label: "50개", description: "표준 (권장)"},
            {label: "100개", description: "포괄적 (느림)"}
        ]
    )

    top_k = extract_number(response)
    execute_moc_generation(topic, top_k)

# 관련 문서 찾기
if user_wants_related:
    # 파일명 또는 경로 입력 받기
    file = ask_text("어떤 문서의 관련 문서를 찾으시겠습니까? (파일명 또는 경로)")

    # vault에서 파일 검색
    found_files = search_file_in_vault(file)

    if len(found_files) > 1:
        # 여러 개 발견: 선택
        selected = ask_user_question(
            question="어느 파일을 선택하시겠습니까?",
            options=create_file_options(found_files)
        )
        file_path = selected
    elif len(found_files) == 1:
        file_path = found_files[0]
    else:
        error("파일을 찾을 수 없습니다")

    execute_related_search(file_path)
```

### 5. 명령어 구성 및 실행

```python
def build_command(query, method="hybrid", rerank=False, expand=False, top_k=10, **kwargs):
    cmd = f"cd ~/git/vault-intelligence && python -m src search --query \"{query}\" --search-method {method} --top-k {top_k}"

    if rerank:
        cmd += " --rerank"

    if expand:
        cmd += " --expand"

    if "threshold" in kwargs:
        cmd += f" --threshold {kwargs['threshold']}"

    if "with_centrality" in kwargs:
        cmd += " --with-centrality"

    if "output" in kwargs:
        cmd += f" --output {kwargs['output']}"

    return cmd

def execute_search(query, **options):
    cmd = build_command(query, **options)
    result = execute_bash(cmd)
    display_formatted_results(result)
    return result
```

## 결과 표시 형식

### 검색 결과

```markdown
🔍 검색어: "TDD 테스트 주도 개발"
📊 검색 방법: hybrid + rerank
⏱️ 소요 시간: 0.8초

📄 검색 결과 (5개):

1. **TDD 실무 가이드** (유사도: 0.8542)
   - 경로: 003-RESOURCES/TDD/TDD-Best-Practices.md
   - 태그: #tdd #testing #practices
   - 미리보기: 테스트 주도 개발의 실무 적용 방법과 모범 사례...

2. **클린 코더스 TDD 강의** (유사도: 0.7234)
   - 경로: 003-RESOURCES/VIDEOS/Clean-Coders-TDD.md
   - 태그: #tdd #video #kent-beck
   - 미리보기: Uncle Bob의 TDD 강의 요약...

[...]

💡 추천 액션:
- 관련 문서 더 보기: /obsidian:vault-query --related "TDD-Best-Practices.md"
- MOC 생성: /obsidian:vault-query --moc "TDD"
```

### 관련 문서 결과

```markdown
🔗 관련 문서: TDD-Best-Practices.md

📚 유사 문서 (10개):

1. **TDD 안티패턴** (유사도: 0.8123)
2. **테스트 더블 사용법** (유사도: 0.7891)
[...]

🏷️ 공통 태그: #tdd, #testing, #practices
🕸️ 지식 그래프 연결: 15개 문서와 연결됨
```

## 주의사항

### 올바른 옵션 사용

**❌ 잘못된 사용:**
```bash
--method semantic      # (X)
--k 20                 # (X)
--top 20               # (X)
--output-file out.md   # (X)
--reranking            # (X)
```

**✅ 올바른 사용:**
```bash
--search-method semantic  # (O)
--top-k 20                # (O)
--output out.md           # (O)
--rerank                  # (O)
```

### 성능 고려사항

- **재순위화 (`--rerank`)**: 정확도 ↑, 속도 ↓ (2-3배 느림)
- **쿼리 확장 (`--expand`)**: 포괄성 ↑, 속도 ↓
- **ColBERT 검색**: 긴 문장에 효과적, 단일 키워드는 hybrid 권장
- **최고 품질**: `--method hybrid --rerank --expand` (가장 느림, 가장 정확)

### 검색 팁

1. **단일 키워드**: hybrid 검색 사용
   ```bash
   /obsidian:vault-query "TDD" --method hybrid
   ```

2. **복합 개념**: ColBERT 또는 hybrid + rerank
   ```bash
   /obsidian:vault-query "test driven development practices" --method colbert
   ```

3. **포괄적 검색**: expand 옵션 추가
   ```bash
   /obsidian:vault-query "리팩토링" --expand
   ```

4. **고정밀 검색**: rerank 옵션 추가
   ```bash
   /obsidian:vault-query "clean code" --rerank
   ```

## 문제 해결

### 검색 결과가 없는 경우

1. 임계값 낮추기: `--threshold 0.2`
2. 검색 방법 변경: `--method semantic`
3. 쿼리 확장: `--expand`
4. 인덱스 재구축: `cd ~/git/vault-intelligence && python -m src reindex`

### 성능이 느린 경우

1. 재순위화 제거
2. 결과 수 줄이기: `--top-k 5`
3. ColBERT 대신 hybrid 사용

### 시스템 초기화

```bash
# vault-intelligence 디렉토리에서
cd ~/git/vault-intelligence

# 인덱스 완전 재구축
python -m src reindex --force

# ColBERT 포함 재구축
python -m src reindex --force --with-colbert
```

## 추가 리소스

- **상세 가이드**: `~/git/vault-intelligence/docs/USER_GUIDE.md`
- **실전 예제**: `~/git/vault-intelligence/docs/EXAMPLES.md`
- **문제 해결**: `~/git/vault-intelligence/docs/TROUBLESHOOTING.md`
- **개발자 문서**: `~/git/vault-intelligence/CLAUDE.md`

이제 $ARGUMENTS를 파싱하여 적절한 vault-intelligence 명령을 실행하고 결과를 사용자 친화적으로 표시하세요.
