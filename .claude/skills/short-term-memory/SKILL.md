---
name: short-term-memory
description: Maintain working context via current-context.md - read before and update after every response with timestamp YYYYMMDD-HHMMSS
---

# Short-term Memory Skill

**Purpose:** Maintain working context across sessions and compactions via `current-context.md`

## Mandatory Workflow

### READ -> WORK -> UPDATE -> CHECK -> SEND

**Before EVERY response:** Read `current-context.md`
**After EVERY response:** Update `current-context.md` with timestamp

```
1. Read current-context.md
2. Do your work
3. Update current-context.md (add timestamp YYYYMMDD-HHMMSS)
4. Check line count (>200? archive old entries)
5. Send response
```

## Critical Rules

### 1. The file lives in the project

The file is `PROJECT_DIRECTORY/current-context.md`. It lives in the project directory, not in `~/.claude/`.

### 2. Timestamp Format

**Use:** `YYYYMMDD-HHMMSS` prefix for all entries. Always get the timestamp from the system clock — never invent one.

```markdown
✅ 20251230-143022 : shipping-mapping.md created (relay cascade)
⏸️ 20251230-150133 pending : API vs FTP decision (contact vendor Jan)
```

### 3. Summaries not Novels

Keep entries short: the WHAT, WHERE, HOW — function names, file names, moves.
Don't keep: the WHY (unless it's a decision), full sentences.

### 4. It's not a task, it's a routine

Do not add "[ ] Update current-context.md" in a todo list. It's a routine, done at every step.

## File Structure

```markdown
# Current Context

**Updated:** YYYYMMDD-HHMMSS
**Phase:** [SPEC/Implementation/Debug/etc.]

---

## 🎯 RIGHT NOW (<10 lines)
- YYYYMMDD-HHMMSS : Current action
- YYYYMMDD-HHMMSS : Just finished

## ✅ Recently Completed (no limit)
- YYYYMMDD-HHMMSS : Action 1

## ✅ Decisions Made (no limit)
- YYYYMMDD-HHMMSS : Decision description

## 🔄 Next Logical Step (<10 lines)
- Before asking "what next?" -> check here

## 💡 Fresh Decisions (<15 lines)
- YYYYMMDD-HHMMSS : Decision awaiting formalization

## ⏸️ Active Blockers (<10 lines)
- YYYYMMDD-HHMMSS pending : Blocker description

## ⚠️ Don't Forget (<15 lines)
- YYYYMMDD-HHMMSS : Explicit DON'T do X

---

**Archived:** [if applicable] See YYYYMMDDHHMMSS.pastcontext.md
```

## Self-Enforcement Mantra

**First thought:** "Have I read current-context.md?"
**Last action:** "Have I updated current-context.md with timestamp?"

**READ -> WORK -> UPDATE (timestamp!) -> CHECK COUNT -> SEND**
