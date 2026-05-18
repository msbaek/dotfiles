---
name: java-structural-ops
description: |
  Use when working with Java codebase — navigation, refactoring, cross-project search.
  Java 프로젝트(특히 5개 규모 multi-project) 작업 시 토큰·속도 절약을 위해 구조 도구 우선 사용.
  단일 프로젝트는 Serena (mcp__serena__*) — find_symbol, find_referencing_symbols, rename_symbol 등.
  다수 프로젝트 동시 검색은 sg --lang java -p '<pattern>'.
  Triggers on: "Java 작업", "Java refactor", "Java 클래스 검색", "find_symbol", "find_referencing_symbols",
  "rename in Java", "Java 다중 프로젝트", "Java multi-project", "Spring Boot navigation",
  "Java 호출 그래프", "incomingCalls", "outgoingCalls".
---

# Java Structural Operations

Java 프로젝트 작업 시 토큰·속도 절약을 위해 구조 도구 우선.
_Serena는 LSP 기반 semantic 분석, sg는 tree-sitter AST 기반 syntactic search._

## 도구 분담 (프로젝트 개수 기준)

### 단일 프로젝트: Serena

- `mcp__serena__find_symbol` — 심볼 정의 위치
- `mcp__serena__find_referencing_symbols` — 호출처/사용처
- `mcp__serena__rename_symbol` — 심볼 일괄 rename
- `mcp__serena__get_symbols_overview` — 파일·디렉토리 심볼 트리
- `mcp__serena__incomingCalls` / `outgoingCalls` — 호출 그래프
- `mcp__serena__goToDefinition` / `documentSymbol` / `workspaceSymbol`

프로젝트 전환: `mcp__serena__activate_project` 호출

### 다수 프로젝트 동시: sg (ast-grep)

```bash
sg --lang java -p '<pattern>' <dir1> <dir2> <dir3> ...
```

- multi-dir 동시 검색 가능 (Serena는 한 번에 한 프로젝트만 활성화)
- tree-sitter AST 기반이라 `grep`보다 정확 (주석·문자열 false-positive 회피)
- 예시:
  ```bash
  sg --lang java -p '@Transactional' ~/git/proj1 ~/git/proj2
  sg --lang java -p '$CLASS extends $BASE' ~/git/{proj1,proj2,proj3}
  ```

## Grep 허용 범위

Java 본체 검색은 위 두 도구로. `rg`/`grep`은 다음에만:

- string literals
- config 파일 (yaml, properties, xml)
- 로그 파일
- 비-Java 파일
- <500 라인 작은 파일

## Fallback 정책

위 도구가 에러 반환 시:

1. 사용자에게 에러 보고
2. Grep 사용 허가 받음
3. 허가 받은 후 `rg` 또는 `sg` (다른 옵션) 시도

자동 fallback 금지 — 사용자가 의도된 도구를 알아야 다음 작업 결정 가능.
