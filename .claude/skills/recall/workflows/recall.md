# Recall Workflow

Load context from vault memory - temporal queries use agf (history.jsonl), topic queries use vis semantic search.

## Step 1: Classify Query

Parse the user's input after `/recall` and classify:

- **Graph** - starts with "graph": "graph last week", "graph yesterday", "graph today"
  -> Go to Step 2C **ONLY** (다른 Step 실행 금지)
- **Temporal** - mentions time: "yesterday", "today", "last week", "this week", a date, "what was I doing", "session history"
  -> Go to Step 2A
- **Topic** - mentions a subject: "QMD video", "authentication", "lab content"
  -> Go to Step 2B
- **Both** - temporal + topic: "what did I do with QMD yesterday"
  -> Go to Step 2A first, then scan results for the topic

## Step 2A: Temporal Recall (agf 활용)

날짜 표현식을 YYYY-MM-DD로 변환한 뒤 agf list.py를 호출합니다.

**날짜 변환 규칙** (Claude가 currentDate 기준으로 계산):
- `yesterday` → 어제 날짜 YYYY-MM-DD
- `today` → 오늘 날짜 YYYY-MM-DD
- `last monday` .. `last sunday` → 해당 요일 날짜
- `YYYY-MM-DD` → 그대로 사용
- `this week`, `last week`, `last N days` → 날짜 범위로 확장하여 각 날짜별 호출

```bash
# 단일 날짜
python3 ~/.claude/skills/agf/list.py YYYY-MM-DD

# 날짜 범위 (last week 등) — 각 날짜별 호출 후 결과 통합
python3 ~/.claude/skills/agf/list.py 2026-03-03
python3 ~/.claude/skills/agf/list.py 2026-03-04
# ... (필요한 날짜만큼 반복)
```

Present the table to the user. If they pick a session to expand:

```bash
python3 ~/.claude/skills/agf/show.py SESSION_ID_PREFIX
```

show.py 출력에서 META/CONV/HISTORY 섹션을 파싱하여 세션 상세 + AI 요약을 제공합니다.
(상세 절차는 `/agf show` 스킬 참조)

## Step 2B: Topic Recall (vis Semantic Search)

vis는 BGE-M3 시맨틱 검색 엔진으로, 키워드 매칭이 아닌 의미적 유사도로 검색합니다. 동의어/유사 표현을 자동으로 처리하므로 별도 쿼리 확장이 불필요합니다.

**Step 2B.1: vis search 실행**

```bash
# vis daemon 서버 실행 시 HTTP API 직접 호출 (0.4초)
curl -s --get --data-urlencode "query=QUERY" "http://localhost:8741/search?rerank=true&top_k=10" | jq -r '.results[] | "\(.score) \(.path)"'

# 서버 미실행 시 fallback
vis search "QUERY" --rerank --top-k 10
```

- HTTP API 우선 사용 (9초 → 0.4초)
- `--rerank`: 재순위화로 정확도 향상 (권장)

결과에서 `claude-session/` 경로는 세션, `notes/` 경로는 노트, `dailies/` 경로는 데일리로 분류.

**Step 2B.2: Deduplicate and filter** — 유사도가 낮은 결과(음수 점수)는 제외. 상위 5개 유의미한 결과만 사용.

## Step 3: Fetch Full Documents (Topic path only)

상위 3개 결과의 전체 내용을 Read 도구로 확인:

```bash
# vis 검색 결과에서 반환된 경로를 직접 읽기
Read /path/to/result.md (offset/limit으로 필요한 부분만)
```

## Step 4: Present Structured Summary

**For temporal queries:** Present the session table and offer to expand any session.

**For topic queries:** Organize results by collection type:

**Sessions**
- What was worked on related to this topic
- Key dates and decisions
- Current status or next steps

**Notes**
- Relevant research findings
- Plans or proposals
- Content drafts

**Daily**
- Recent daily log entries mentioning this topic
- Timestamps and context

Keep this concise - it's context loading, not a full report.

## Step 5: Synthesize "One Thing"

After presenting recall results (temporal, topic, or graph), synthesize the single highest-leverage next action. This replaces generic "what would you like to work on?" with a concrete recommendation.

**How to pick the One Thing:**
1. Look at what has momentum - sessions with recent activity, things mid-flow
2. Look at what's blocked - removing a blocker unlocks downstream work
3. Look at what's closest to done - finishing > starting
4. Weigh urgency signals: deadlines in session titles, "blocked" status, time-sensitive content

**Format:** Bold line at the end of results:

> **One Thing: [specific, concrete action]**

**Good examples:**
- **One Thing: Finish the QMD video outline - sections 3-5 are drafted, just needs the closing CTA**
- **One Thing: Unblock the lab deploy - the DNS config is the only remaining blocker, everything else is ready**
- **One Thing: Record the video intro - the script and thumbnail are done, recording is the bottleneck**

**Bad examples (too generic):**
- "Continue working on the video"
- "Pick up where you left off"
- "Review recent progress"

If the recall results don't have enough signal to pick a clear One Thing (e.g. user just browsed old sessions with no active work), skip it and ask "What would you like to work on from here?" instead.

## Fallback: No Results Found

If no results are found:

```
No results found for "QUERY". Try:
- Different search terms
- Broader keywords / different date range
- --min-msgs 1 to include short sessions
```

## Step 2C: Graph Visualization

Strip "graph" prefix from query to get the date expression. **반드시 1회만 호출** — 스크립트가 내부적으로 날짜 범위를 처리합니다.

**중요: DATE_EXPR을 그대로 전달할 것.** 날짜 변환/분할하지 말 것. Step 2A의 agf 방식과 다름.

```bash
# 정확히 이 명령어를 1회만 실행 — --no-open 필수
python3 ~/.claude/skills/recall/scripts/session-graph.py DATE_EXPR --min-msgs 1 --no-open
```

스크립트 완료 후, stdout의 "Saved to PATH" 줄에서 경로를 추출하여 별도로 1회만 open:
```bash
open /path/to/session-graph.html
```

지원되는 DATE_EXPR (스크립트가 내부 처리):
- `yesterday`, `today`
- `YYYY-MM-DD`
- `last week`, `this week`
- `last N days`

추가 Options (필요 시):
- `--all-projects` - 모든 프로젝트 세션 포함 (기본: 현재 프로젝트만)
- `--min-files N` - only show sessions touching N+ files (default: 3)
- `-o PATH` - custom output path

**⚠️ 금지사항:**
- Graph 쿼리는 Step 2C만 실행합니다. Step 2A(temporal)를 함께 실행하지 마세요.
- open 명령은 반드시 1회만 실행합니다. 스크립트에 --no-open을 반드시 붙이세요.

스크립트 실행 후 stdout에서 노드/엣지 수를 파싱하여 사용자에게 보고합니다.
Session nodes colored by day, file nodes colored by folder. Clusters와 shared files를 안내합니다.

## Notes

- Temporal queries go through `agf/list.py` + `agf/show.py` (history.jsonl 인덱스 활용, 빠르고 정확)
- Graph queries go through `session-graph.py` (NetworkX + pyvis)
- Topic queries use `vis search` (BGE-M3 semantic search) with `--rerank` for accuracy
- vis는 vault 전체(세션, 노트, 데일리)를 단일 검색으로 커버 — 별도 컬렉션 분리 불필요
- 결과 경로의 디렉토리명으로 자동 분류: `claude-session/` = 세션, `notes/dailies/` = 데일리, 그 외 = 노트
