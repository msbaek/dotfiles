# Design: vis graph — 문서 관계 그래프 시각화

Created: 2026-03-08

## Goal

vis CLI에 `graph` 서브커맨드를 추가하여 Obsidian vault 문서 간 관계를 인터랙티브 HTML 그래프로 시각화.

## 사용 시나리오

- **Primary**: 탐색/발견 — 문서 중심으로 관련 문서들을 시각적으로 브라우징하며 미발견 연결 발견
- **Future**: 구조 파악 (주제별 분포), 큐레이션 (정리/중복 감지)

## CLI Interface

```bash
# 문서 기준 (v1)
vis graph "문서.md" [--top-k 10] [--threshold 0.3] [--no-open] [-o PATH]

# 주제 기준 (v2, 향후)
vis graph --topic "TDD" [--top-k 20] [--threshold 0.3] [--no-open] [-o PATH]
```

## Architecture

```
vis graph "문서.md"
  → AdvancedSearch.find_related(문서) → [(path, score), ...]
  → WikilinkParser.extract(문서 + related 문서들) → {source: [targets]}
  → GraphBuilder: 노드(문서) + 엣지(실선=wikilink, 점선=시맨틱) 생성
  → PyvisRenderer: Obsidian 테마 HTML 출력
```

### 접근법: vis 내부 API 직접 활용

- `AdvancedSearch.find_related()` 를 직접 호출하여 유사도 데이터 획득
- CLI 파싱 불필요, BGE-M3 로딩 1회만 발생
- 유사도 점수를 float으로 바로 사용 → 엣지 두께/색상 매핑 정확

## Node Design

| 속성 | 값 |
|------|-----|
| 중심 문서 | 큰 원, 강조색 (gold 계열) |
| 관련 문서 | 크기 = 유사도 비례, 색상 = 폴더별 (FOLDER_COLORS) |
| 라벨 | 파일명 (.md 제거) |
| hover | 전체 경로 + 유사도 점수 |

## Edge Design

| 타입 | 스타일 | 의미 |
|------|--------|------|
| wikilink | 실선, 불투명 | 이미 연결된 문서 |
| 시맨틱 only | 점선, 반투명 | 발견된 관계 (아직 미연결) |
| 양쪽 다 | 실선, 두꺼움 | wikilink + 높은 유사도 |

## File Structure (vault-intelligence 프로젝트)

```
vault-intelligence/
  src/
    features/
      knowledge_graph.py    # GraphBuilder + WikilinkParser
    visualization/
      graph_renderer.py     # PyvisRenderer (Obsidian 테마)
  # __main__.py에 graph 서브커맨드 등록
```

## Wikilink Parsing

- `[[문서명]]`, `[[문서명|별칭]]` 패턴을 regex로 추출
- vault 내 실제 파일 경로와 매칭
- 양방향 링크 모두 수집 (A→B, B→A)

## Scope

### v1 (현재)
- 문서 기준 그래프 (`vis graph "문서.md"`)
- 실선(wikilink) + 점선(시맨틱 유사도) 구분
- pyvis HTML, Obsidian 테마
- `--top-k`, `--threshold`, `--no-open`, `-o` 옵션

### v2 (향후)
- 주제 기준 그래프 (`vis graph --topic "TDD"`)
- 구조 파악 / 큐레이션 기능 (클러스터링, 중복 표시)
- 2-depth 이상 탐색 (관련 문서의 관련 문서)

## Dependencies

- pyvis (session-graph.py에서 이미 사용 중, vis 프로젝트에 추가 필요)
- networkx (동일)

## Constraints

- vis 프로젝트 내에서 구현 (~/git/vault-intelligence/)
- session-graph.py의 Obsidian 테마/인터랙션 스타일 차용하되 코드는 독립
- BGE-M3 초기화 오버헤드 최소화 (1회만 로딩)
