---
name: recall
description: Load context from vault memory. Temporal queries (yesterday, last week, session history) use agf (history.jsonl) for fast session lookup. Topic queries use vis semantic search. "recall graph" generates interactive temporal graph of sessions and files. Every recall ends with "One Thing" - the single highest-leverage next action synthesized from results. Use when user says "recall", "what did we work on", "load context about", "remember when we", "prime context", "yesterday", "what was I doing", "last week", "session history", "recall graph", "session graph".
argument-hint: [yesterday|today|last week|this week|TOPIC|graph DATE_EXPR]
allowed-tools: Bash(vis:*), Bash(python3:*)
---

# Recall Skill

Three modes: temporal (date-based session timeline), topic (vis semantic search across vault), and graph (interactive visualization of session-file relationships). Every recall ends with the **One Thing** - a concrete, highest-leverage next action synthesized from the results.

## What It Does

- **Temporal queries** ("yesterday", "last week", "what was I doing"): agf 스크립트(history.jsonl 인덱스)를 활용하여 날짜별 세션 목록을 빠르게 조회. 세션 상세 보기도 agf show로 처리.
- **Topic queries** ("authentication", "TDD"): vis semantic search across vault (sessions, notes, daily logs).
- **Graph queries** ("graph yesterday", "graph last week"): Generates an interactive HTML graph showing sessions as nodes connected to files they touched. Sessions colored by day, files colored by folder. Clusters reveal related work streams, shared files show cross-session dependencies.
- **One Thing synthesis**: After presenting results, synthesizes the single most impactful next action based on what has momentum, what's blocked, and what's closest to done. Not generic - specific and actionable.

No custom setup needed for temporal recall - agf가 history.jsonl 인덱스를 활용하여 빠르게 조회합니다.

## Usage

```
/recall yesterday
/recall last week
/recall 2026-02-25
/recall authentication work
/recall TDD 리팩토링
```

**Graph mode** - visualize session relationships over time:
```
/recall graph yesterday        # what you touched today
/recall graph last week        # week overview - find clusters
/recall graph this week        # current week so far
/recall graph last 3 days      # recent activity window
```

Graph options: `--min-files 5` for cleaner graphs (only sessions touching 5+ files), `--all-projects` to scan beyond current vault.

## Workflow

See `workflows/recall.md` for routing logic and step-by-step process.
