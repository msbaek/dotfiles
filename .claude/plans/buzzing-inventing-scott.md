# CLAUDE.md 최적화 계획

## 사용자 선택 사항
- **언어**: 한국어 유지
- **기존 내용**: 일부 간소화
- **XML 적용**: 핵심 규칙만

---

## 수정할 파일
- `~/.claude/CLAUDE.md`

---

## 최종 구조 (개선안)

```markdown
## Ground Rule

<default_to_action>
사용자 의도가 불명확할 때도 가장 유용한 행동을 추론하여 실행.
제안만 하지 말고 실제로 변경 사항을 구현할 것.
</default_to_action>

<investigate_before_answering>
코드나 파일에 대해 답변하기 전에 반드시 먼저 읽고 확인할 것.
읽지 않은 코드에 대해 추측하거나 가정하지 말 것.
</investigate_before_answering>

<avoid_overengineering>
요청된 것만 구현. 추가 기능, 리팩토링, 개선사항 임의 추가 금지.
버그 수정에 주변 코드 정리 불필요. 단순 기능에 과도한 설정 불필요.
</avoid_overengineering>

### 언어 및 소통
- 한국어로 답변
- 나에 대한 정보: ~/git/aboutme/AI-PROFILE.md 참조

### 작업 패턴
- 프로젝트 시작 전 항상 plan mode로 시작
- 계획은 .claude/tasks/[taskname].md에 저장
- 응답 끝에 "Uncertainty Map" 섹션 추가

### 정보 부족 시
- 충분한 정보가 없으면 먼저 질문
- API/SDK/라이브러리 사용 시 CONTEXT7 MCP 도구로 확인

### 프롬프트 prefix
| Prefix | 동작 |
|--------|------|
| `EP:` | ~/.claude/Prompt-Enhancer.md 참조하여 프롬프트 개선 |
| `EP2:` | ~/.claude/Prompt-Enhancer2.md 참조하여 프롬프트 개선 |
| `java-guide:` | ~/.claude/docs/JAVA-APP-GUIDE.md 참조 |
| `snippet:` | ~/.claude/docs/snippets.md 참조 |

## 도구 사용

### 검색/탐색 도구
| 작업 | 사용할 도구 | 이유 |
|------|------------|------|
| 구문 인식 검색 | `sg --lang <언어> -p '<패턴>'` | 구조적 매칭에 최적화 |
| 텍스트 검색 | `rg` (ripgrep) | grep보다 빠르고 .gitignore 자동 존중 |
| 파일 찾기 | `fd` | find보다 빠르고 직관적 |

### 병렬 처리
대규모 파일 분석이나 vault 정리 작업 시 Task 도구와 sub-agent를 적극 활용하여 병렬 처리

### 대규모 변경 시
처음 몇 가지 샘플을 먼저 보여주고 확인 받은 후 전체 작업 진행

## LEARNING

작업 중 다음 번에 더 빠르게 작업할 수 있는 정보 발견 시 프로젝트의 ai-learnings.md에 기록

## Obsidian Vault 작업

### 경로
- vault-intelligence: `~/git/vault-intelligence/`
- vault: `~/DocumentsLocal/msbaek_vault/`

### 태그 체계
- Hierarchical tags: `#category/subcategory/detail`
- 5가지 카테고리: Topic, Document Type, Source, Status, Project
- Zettelkasten: 000-SLIPBOX, 001-INBOX, 003-RESOURCES

### vault-intelligence CLI
```bash
cd ~/git/vault-intelligence
python -m src search --query "검색어" --search-method hybrid --top-k 10
```

옵션: `--search-method` (semantic|keyword|hybrid|colbert), `--rerank`, `--expand`

### 파일 처리 오류
- 읽기 오류 파일은 UNPROCESSED-FILES.md에 기록
- Canvas/이미지 파일은 태그 적용 제외
```

---

## 간소화 대상

### 제거/병합할 내용
1. **중복된 도구 관련 키워드 설명** - 표 형식으로 통합
2. **Vault Intelligence 상세 옵션 설명** - 핵심만 남기고 상세 가이드 파일 참조로 대체
3. **태그 체계 중복 설명** - 하나로 통합

---

## 추가할 핵심 XML 태그 (3개)

### 1. `<default_to_action>`
```xml
<default_to_action>
사용자 의도가 불명확할 때도 가장 유용한 행동을 추론하여 실행.
제안만 하지 말고 실제로 변경 사항을 구현할 것.
</default_to_action>
```

### 2. `<investigate_before_answering>`
```xml
<investigate_before_answering>
코드나 파일에 대해 답변하기 전에 반드시 먼저 읽고 확인할 것.
읽지 않은 코드에 대해 추측하거나 가정하지 말 것.
</investigate_before_answering>
```

### 3. `<avoid_overengineering>`
```xml
<avoid_overengineering>
요청된 것만 구현. 추가 기능, 리팩토링, 개선사항 임의 추가 금지.
버그 수정에 주변 코드 정리 불필요. 단순 기능에 과도한 설정 불필요.
</avoid_overengineering>
```

---

## 구현 순서

1. 새 구조로 전체 재작성
2. 핵심 XML 태그 3개 추가
3. 중복 내용 간소화
4. 표 형식으로 가독성 향상
