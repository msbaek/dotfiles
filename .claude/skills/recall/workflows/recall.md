# Recall Workflow

Load context from vault memory - temporal queries use native JSONL files, topic queries use vis semantic search.

## Step 1: Classify Query

Parse the user's input after `/recall` and classify:

- **Graph** - starts with "graph": "graph last week", "graph yesterday", "graph today"
  -> Go to Step 2C
- **Temporal** - mentions time: "yesterday", "today", "last week", "this week", a date, "what was I doing", "session history"
  -> Go to Step 2A
- **Topic** - mentions a subject: "QMD video", "authentication", "lab content"
  -> Go to Step 2B
- **Both** - temporal + topic: "what did I do with QMD yesterday"
  -> Go to Step 2A first, then scan results for the topic

## Step 2A: Temporal Recall (JSONL Timeline)

Run the recall-day script from the skill's scripts directory:

```bash
python3 .claude/skills/recall/scripts/recall-day.py list DATE_EXPR
```

Replace `DATE_EXPR` with the parsed date expression. Supported:
- `yesterday`, `today`
- `YYYY-MM-DD`
- `last monday` .. `last sunday`
- `this week`, `last week`
- `N days ago`, `last N days`

Options:
- `--min-msgs N` - filter noise (default: 3)
- `--all-projects` - scan all projects, not just current vault

Present the table to the user. If they pick a session to expand:

```bash
python3 .claude/skills/recall/scripts/recall-day.py expand SESSION_ID
```

This shows the conversation flow (user messages, assistant first lines, tool calls).

## Step 2B: Topic Recall (vis Semantic Search)

vis는 BGE-M3 시맨틱 검색 엔진으로, 키워드 매칭이 아닌 의미적 유사도로 검색합니다. 동의어/유사 표현을 자동으로 처리하므로 별도 쿼리 확장이 불필요합니다.

**Step 2B.1: vis search 실행**

```bash
vis search "QUERY" --rerank --top-k 10
```

- `--rerank`: 재순위화로 정확도 향상 (권장)
- `--top-k 10`: 상위 10개 결과

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

Strip "graph" prefix from query to get the date expression. Run:

```bash
python3 .claude/skills/recall/scripts/session-graph.py DATE_EXPR
```

Options:
- `--min-files N` - only show sessions touching N+ files (default: 2, use 5+ for cleaner graphs)
- `--min-msgs N` - filter noise (default: 3)
- `--all-projects` - scan all projects
- `-o PATH` - custom output path (default: /tmp/session-graph.html)
- `--no-open` - don't auto-open browser

Opens interactive HTML in browser. Session nodes colored by day, file nodes colored by folder.
Tell the user the node/edge counts and what to look for (clusters, shared files).

## Notes

- Temporal queries go through `recall-day.py` (native JSONL)
- Graph queries go through `session-graph.py` (NetworkX + pyvis)
- Topic queries use `vis search` (BGE-M3 semantic search) with `--rerank` for accuracy
- vis는 vault 전체(세션, 노트, 데일리)를 단일 검색으로 커버 — 별도 컬렉션 분리 불필요
- 결과 경로의 디렉토리명으로 자동 분류: `claude-session/` = 세션, `notes/dailies/` = 데일리, 그 외 = 노트
