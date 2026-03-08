# vis graph — 문서 관계 그래프 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** vis CLI에 `graph` 서브커맨드를 추가하여 문서 간 관계를 인터랙티브 pyvis HTML 그래프로 시각화

**Architecture:** `AdvancedSearchEngine.get_related_documents()` API로 시맨틱 유사도 데이터를 얻고, Obsidian wikilink를 regex로 파싱하여 기존 연결도 추출. 두 관계를 NetworkX 그래프로 합치고 pyvis로 Obsidian 테마 HTML 렌더링.

**Tech Stack:** Python, NetworkX, pyvis, BGE-M3 (vis 내부), regex (wikilink parsing)

**Project:** `~/git/vault-intelligence/`

**기존 자산:**
- `src/features/knowledge_graph.py` — KnowledgeGraphBuilder 존재 (matplotlib 기반, 본 프로젝트에서는 사용하지 않음)
- `src/features/advanced_search.py:1012` — `get_related_documents()` API
- `src/__main__.py:556` — `run_related_documents()` 함수 참고
- `~/.claude/skills/recall/scripts/session-graph.py` — pyvis 렌더링 스타일 참고 (복사하지 않고 스타일만 차용)

---

### Task 1: WikilinkParser 구현

**Files:**
- Create: `src/features/wikilink_parser.py`
- Test: `tests/test_wikilink_parser.py`

**Step 1: Write the failing test**

```python
# tests/test_wikilink_parser.py
import pytest
from src.features.wikilink_parser import WikilinkParser


def test_extract_wikilinks_basic():
    content = "See [[Document A]] and [[Document B|별칭]]."
    parser = WikilinkParser("/fake/vault")
    links = parser.extract_from_content(content)
    assert links == ["Document A", "Document B"]


def test_extract_wikilinks_with_heading():
    content = "See [[Document A#heading]]."
    parser = WikilinkParser("/fake/vault")
    links = parser.extract_from_content(content)
    assert links == ["Document A"]


def test_extract_wikilinks_empty():
    content = "No links here."
    parser = WikilinkParser("/fake/vault")
    links = parser.extract_from_content(content)
    assert links == []
```

**Step 2: Run test to verify it fails**

Run: `cd ~/git/vault-intelligence && python -m pytest tests/test_wikilink_parser.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# src/features/wikilink_parser.py
"""Obsidian wikilink parser for knowledge graph."""

import re
from pathlib import Path

WIKILINK_RE = re.compile(r'\[\[([^\]|#]+?)(?:#[^\]|]*)?(?:\|[^\]]*?)?\]\]')


class WikilinkParser:
    """Extract and resolve Obsidian wikilinks from markdown files."""

    def __init__(self, vault_path: str):
        self.vault_path = Path(vault_path)

    def extract_from_content(self, content: str) -> list[str]:
        """Extract wikilink targets from markdown content."""
        return list(dict.fromkeys(m.group(1).strip() for m in WIKILINK_RE.finditer(content)))

    def extract_from_file(self, file_path: str) -> list[str]:
        """Extract wikilinks from a file."""
        try:
            full = self.vault_path / file_path
            content = full.read_text(encoding='utf-8')
            return self.extract_from_content(content)
        except (OSError, UnicodeDecodeError):
            return []

    def resolve_link(self, link_name: str) -> str | None:
        """Resolve a wikilink name to a vault-relative file path."""
        # Exact match first
        for md in self.vault_path.rglob(f"{link_name}.md"):
            return str(md.relative_to(self.vault_path))
        # Case-insensitive fallback
        lower = link_name.lower()
        for md in self.vault_path.rglob("*.md"):
            if md.stem.lower() == lower:
                return str(md.relative_to(self.vault_path))
        return None
```

**Step 4: Run test to verify it passes**

Run: `cd ~/git/vault-intelligence && python -m pytest tests/test_wikilink_parser.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add src/features/wikilink_parser.py tests/test_wikilink_parser.py
git commit -m "feat(graph): add WikilinkParser for Obsidian wikilink extraction"
```

---

### Task 2: GraphRenderer (pyvis HTML 출력)

**Files:**
- Create: `src/visualization/__init__.py`
- Create: `src/visualization/graph_renderer.py`
- Test: `tests/test_graph_renderer.py`

**Step 1: Write the failing test**

```python
# tests/test_graph_renderer.py
import pytest
import tempfile
from pathlib import Path
from src.visualization.graph_renderer import KnowledgeGraphRenderer, GraphNode, GraphEdge


def test_render_empty_graph():
    renderer = KnowledgeGraphRenderer()
    with tempfile.NamedTemporaryFile(suffix='.html', delete=False) as f:
        result = renderer.render([], [], f.name, "Test Graph")
    assert result is True
    assert Path(f.name).exists()
    content = Path(f.name).read_text()
    assert "Test Graph" in content


def test_render_with_nodes_and_edges():
    nodes = [
        GraphNode(id="center", label="Center Doc", path="a.md", is_center=True, score=1.0),
        GraphNode(id="related", label="Related Doc", path="b.md", is_center=False, score=0.8),
    ]
    edges = [
        GraphEdge(source="center", target="related", edge_type="semantic", weight=0.8),
    ]
    renderer = KnowledgeGraphRenderer()
    with tempfile.NamedTemporaryFile(suffix='.html', delete=False) as f:
        result = renderer.render(nodes, edges, f.name, "Test")
    assert result is True
    content = Path(f.name).read_text()
    assert "Center Doc" in content
```

**Step 2: Run test to verify it fails**

Run: `cd ~/git/vault-intelligence && python -m pytest tests/test_graph_renderer.py -v`
Expected: FAIL with "ModuleNotFoundError"

**Step 3: Write minimal implementation**

```python
# src/visualization/__init__.py
# Visualization package

# src/visualization/graph_renderer.py
"""PyVis-based knowledge graph renderer with Obsidian theme."""

from dataclasses import dataclass
from pathlib import Path

import networkx as nx
from pyvis.network import Network


@dataclass
class GraphNode:
    id: str
    label: str
    path: str
    is_center: bool
    score: float
    folder: str = ""
    tags: list[str] | None = None


@dataclass
class GraphEdge:
    source: str
    target: str
    edge_type: str  # "wikilink", "semantic", "both"
    weight: float


# Obsidian-inspired palette (from session-graph.py)
FOLDER_COLORS = {
    "000-SLIPBOX": "#B4A7FA",
    "001-INBOX": "#FDE68A",
    "002-PRIVATE": "#FCA5A5",
    "003-RESOURCES": "#7DDCB5",
    "004-ARCHIVE": "#CBD5E1",
    "notes": "#93C5FD",
}

CENTER_COLOR = "#FFD700"  # gold
DEFAULT_COLOR = "#78909C"


def _folder_color(path: str) -> str:
    parts = path.split('/')
    if parts:
        for prefix, color in FOLDER_COLORS.items():
            if parts[0].startswith(prefix) or parts[0] == prefix:
                return color
    return DEFAULT_COLOR


class KnowledgeGraphRenderer:
    """Render knowledge graph as interactive pyvis HTML."""

    def render(
        self,
        nodes: list[GraphNode],
        edges: list[GraphEdge],
        output_path: str,
        title: str,
    ) -> bool:
        G = nx.Graph()

        for n in nodes:
            color = CENTER_COLOR if n.is_center else _folder_color(n.path)
            size = 25 if n.is_center else max(8, int(n.score * 20))
            G.add_node(
                n.id,
                label=n.label,
                title=f"{n.path}\nScore: {n.score:.3f}",
                color=color,
                size=size,
                shape="dot",
                font={'size': 14 if n.is_center else 11,
                      'color': '#dcddde',
                      'strokeWidth': 2,
                      'strokeColor': '#1e1e1e'},
            )

        for e in edges:
            if e.edge_type == "wikilink":
                style = {'color': '#7DDCB5', 'opacity': 0.8}
                width = 1.5
                dashes = False
            elif e.edge_type == "both":
                style = {'color': '#B4A7FA', 'opacity': 0.9}
                width = 2.5
                dashes = False
            else:  # semantic
                style = {'color': '#FDBA8C', 'opacity': 0.4}
                width = max(0.5, e.weight * 2)
                dashes = True

            G.add_edge(
                e.source, e.target,
                title=f"{e.edge_type} ({e.weight:.3f})",
                color=style,
                width=width,
                dashes=dashes,
            )

        net = Network(
            height="100vh",
            width="100%",
            bgcolor="#1e1e1e",
            font_color="#dcddde",
            directed=False,
            select_menu=False,
            filter_menu=False,
        )
        net.from_nx(G)
        net.set_options('''{
            "physics": {
                "forceAtlas2Based": {
                    "gravitationalConstant": -80,
                    "centralGravity": 0.01,
                    "springLength": 120,
                    "springConstant": 0.08,
                    "damping": 0.4
                },
                "solver": "forceAtlas2Based",
                "stabilization": {"iterations": 150}
            },
            "interaction": {
                "hover": true,
                "tooltipDelay": 100,
                "navigationButtons": false,
                "keyboard": {"enabled": true}
            }
        }''')

        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        net.save_graph(output_path)

        # Inject title and legend into HTML
        _inject_html_extras(output_path, title)
        return True


def _inject_html_extras(path: str, title: str):
    """Inject title bar and edge legend into the generated HTML."""
    html = Path(path).read_text(encoding='utf-8')
    legend = f'''
    <div style="position:fixed;top:10px;left:10px;z-index:1000;
                background:#262626;padding:12px 16px;border-radius:8px;
                border:1px solid #3e3e3e;font-family:monospace;color:#dcddde;font-size:13px;">
        <div style="font-size:15px;font-weight:bold;margin-bottom:8px;">{title}</div>
        <div><span style="color:#7DDCB5;">━━</span> wikilink (existing)</div>
        <div><span style="color:#FDBA8C;">╌╌</span> semantic (discovered)</div>
        <div><span style="color:#B4A7FA;">━━</span> both</div>
        <div style="margin-top:6px;"><span style="color:#FFD700;">●</span> center document</div>
    </div>
    '''
    html = html.replace('<body>', f'<body>{legend}', 1)
    Path(path).write_text(html, encoding='utf-8')
```

**Step 4: Run test to verify it passes**

Run: `cd ~/git/vault-intelligence && python -m pytest tests/test_graph_renderer.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add src/visualization/ tests/test_graph_renderer.py
git commit -m "feat(graph): add PyVis knowledge graph renderer with Obsidian theme"
```

---

### Task 3: graph 서브커맨드 핸들러 (run_graph)

**Files:**
- Modify: `src/__main__.py` (subparser 등록 + run_graph 함수)

**Step 1: Write run_graph function**

`src/__main__.py`에 `run_related_documents()` (line 556) 근처에 추가:

```python
def run_graph(vault_path: str, file_path: str, top_k: int, config: dict,
              similarity_threshold: float = 0.3, output_file: str = None,
              no_open: bool = False):
    """문서 관계 그래프 생성"""
    try:
        print(f"📊 '{file_path}' 관계 그래프 생성 중...")

        # 1. Search engine init + get related docs
        cache_dir = str(data_dir / "cache")
        search_engine = AdvancedSearchEngine(vault_path, cache_dir, config)

        if not search_engine.indexed:
            print("📚 인덱스 구축 중...")
            if not search_engine.build_index():
                print("❌ 인덱스 구축 실패")
                return False

        related_results = search_engine.get_related_documents(
            document_path=file_path,
            top_k=top_k,
            include_centrality_boost=True,
            similarity_threshold=similarity_threshold
        )

        if not related_results:
            print("❌ 관련 문서를 찾을 수 없습니다.")
            return False

        # 2. Parse wikilinks
        from .features.wikilink_parser import WikilinkParser
        wl_parser = WikilinkParser(vault_path)

        all_paths = [file_path] + [r.document.path for r in related_results]
        wikilinks = {}  # source_path -> [target_paths]
        for p in all_paths:
            raw_links = wl_parser.extract_from_file(p)
            resolved = []
            for link in raw_links:
                target = wl_parser.resolve_link(link)
                if target and target in all_paths:
                    resolved.append(target)
            if resolved:
                wikilinks[p] = resolved

        # 3. Build graph data
        from .visualization.graph_renderer import (
            KnowledgeGraphRenderer, GraphNode, GraphEdge
        )

        nodes = [GraphNode(
            id=file_path, label=Path(file_path).stem,
            path=file_path, is_center=True, score=1.0
        )]
        score_map = {}
        for r in related_results:
            p = r.document.path
            nodes.append(GraphNode(
                id=p, label=Path(p).stem,
                path=p, is_center=False, score=r.similarity_score,
                tags=r.document.tags or []
            ))
            score_map[p] = r.similarity_score

        # Edges: combine wikilinks + semantic
        edge_set = {}  # (src, tgt) -> edge_type
        # Semantic edges
        for r in related_results:
            key = tuple(sorted([file_path, r.document.path]))
            edge_set[key] = ("semantic", r.similarity_score)

        # Wikilink edges
        for src, targets in wikilinks.items():
            for tgt in targets:
                key = tuple(sorted([src, tgt]))
                if key in edge_set:
                    edge_set[key] = ("both", edge_set[key][1])
                else:
                    edge_set[key] = ("wikilink", score_map.get(tgt, 0.5))

        edges = [
            GraphEdge(source=k[0], target=k[1], edge_type=v[0], weight=v[1])
            for k, v in edge_set.items()
        ]

        # 4. Render
        out = output_file or str(Path(vault_path) / ".obsidian-tools" / "knowledge-graph.html")
        renderer = KnowledgeGraphRenderer()
        title = f"Knowledge Graph: {Path(file_path).stem}"
        renderer.render(nodes, edges, out, title)

        print(f"\nGraph: {len(nodes)} nodes, {len(edges)} edges")
        print(f"  Wikilink: {sum(1 for e in edges if e.edge_type == 'wikilink')}")
        print(f"  Semantic: {sum(1 for e in edges if e.edge_type == 'semantic')}")
        print(f"  Both: {sum(1 for e in edges if e.edge_type == 'both')}")
        print(f"Saved to {out}")

        if not no_open:
            import webbrowser
            webbrowser.open(f"file://{out}")

        return True

    except Exception as e:
        print(f"❌ 그래프 생성 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
```

**Step 2: Register graph subparser**

`src/__main__.py`에서 `related` subparser 등록 부근 (line 1908)에 추가:

```python
    # graph subcommand
    p = subparsers.add_parser("graph", help="문서 관계 그래프 시각화")
    p.add_argument("file", help="기준 문서 경로")
    p.add_argument("--top-k", type=int, default=10, help="관련 문서 수 (기본값: 10)")
    p.add_argument("--threshold", type=float, default=0.3, help="유사도 임계값 (기본값: 0.3)")
    p.add_argument("--no-open", action="store_true", help="브라우저 열지 않음")
    p.add_argument("-o", "--output", default=None, help="출력 파일 경로")
```

**Step 3: Add command handler**

`src/__main__.py`에서 `related` 핸들러 (line 2167) 부근에 추가:

```python
    elif args.command == "graph":
        if not check_dependencies():
            sys.exit(1)

        if run_graph(
            vault_path,
            args.file,
            args.top_k,
            config,
            similarity_threshold=args.threshold,
            output_file=args.output,
            no_open=args.no_open,
        ):
            print("✅ 그래프 생성 완료!")
        else:
            print("❌ 그래프 생성 실패!")
            sys.exit(1)
```

**Step 4: Test manually**

Run: `cd ~/DocumentsLocal/msbaek_vault && vis graph "003-RESOURCES/TOOLS/MAC/Homebrew-큐레이션-목록.md" --no-open`
Expected: HTML 파일 생성, 노드/엣지 수 출력

**Step 5: Commit**

```bash
git add src/__main__.py
git commit -m "feat(graph): add graph subcommand to vis CLI"
```

---

### Task 4: pyvis 의존성 추가

**Files:**
- Modify: `requirements.txt` or `pyproject.toml` (vis 프로젝트의 의존성 파일)

**Step 1: Check current dependency file**

Run: `cat ~/git/vault-intelligence/requirements.txt` 또는 `cat ~/git/vault-intelligence/pyproject.toml`

**Step 2: Add pyvis dependency**

`pyvis` 와 `networkx`가 없으면 추가. 있으면 skip.

**Step 3: Install**

Run: `cd ~/git/vault-intelligence && pip install pyvis`

**Step 4: Commit**

```bash
git add requirements.txt  # or pyproject.toml
git commit -m "chore: add pyvis dependency for graph visualization"
```

---

### Task 5: 통합 테스트 및 정리

**Step 1: End-to-end test (문서 기준)**

Run: `vis graph "003-RESOURCES/TOOLS/MAC/Homebrew-큐레이션-목록.md" --top-k 5`
Expected: 브라우저에 그래프 열림, 중심 문서(gold) + 관련 문서(폴더별 색상), 실선/점선 엣지 구분

**Step 2: Edge case test**

Run: `vis graph "존재하지않는.md"`
Expected: "관련 문서를 찾을 수 없습니다" 에러

**Step 3: Option test**

Run: `vis graph "003-RESOURCES/TOOLS/MAC/Homebrew-큐레이션-목록.md" --top-k 20 --threshold 0.5 --no-open -o /tmp/test-graph.html`
Expected: `/tmp/test-graph.html` 생성, 브라우저 안 열림

**Step 4: Final commit**

```bash
git commit -m "feat(graph): complete vis graph v1 - document relationship visualization"
```
