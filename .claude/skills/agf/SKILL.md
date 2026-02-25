---
name: agf
description: |
  Claude Code 세션 탐색 및 분석. agf 데이터 소스(history.jsonl)를 활용한 세션 리스트 조회 및 상세 분석.
  "세션 목록", "session list", "agf" 등의 요청 시 자동 적용.
---

# agf - Session Explorer Skill

## 개요

agf(AI Agent Session Finder)의 데이터 소스인 `~/.claude/history.jsonl`과 세션 JSONL 파일을 활용하여 Claude Code 세션을 프로그래밍 방식으로 탐색·분석하는 skill.

## 사용 방식

| 커맨드 | 설명 |
|--------|------|
| `/agf list` | 오늘 세션 리스트 |
| `/agf list YYYY-MM-DD` | 특정 날짜 세션 리스트 |
| `/agf show <session-id-prefix>` | 특정 세션 상세 + AI 요약 |

## 경로 정보

| 항목 | 경로 |
|------|------|
| 세션 인덱스 | `~/.claude/history.jsonl` |
| 세션 데이터 | `~/.claude/projects/<project-dir>/<sessionId>.jsonl` |
| 디렉토리 매핑 | 비영숫자 문자를 `-`로 치환 (예: `/Users/msbaek/dotfiles` → `-Users-msbaek-dotfiles`) |

---

## list 커맨드

인수가 없으면 오늘 날짜, YYYY-MM-DD 형식이면 해당 날짜의 세션 목록을 출력합니다.

### 실행 절차

1. **날짜 결정** — 인수에서 `list` 다음 값이 YYYY-MM-DD 형식이면 해당 날짜, 없으면 오늘
2. **Bash로 python3 스크립트 실행** — 아래 스크립트의 `{TARGET_DATE}`를 치환하여 실행
3. **결과를 사용자에게 표시** — 스크립트 출력을 그대로 표시

### python3 스크립트 (TARGET_DATE 치환 필요)

```python
import json, os, datetime, re

HISTORY = os.path.expanduser("~/.claude/history.jsonl")
PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
TARGET = "{TARGET_DATE}"

if not os.path.exists(HISTORY):
    print("ERROR: ~/.claude/history.jsonl 파일을 찾을 수 없습니다.")
    raise SystemExit(1)

y, m, d = int(TARGET[:4]), int(TARGET[5:7]), int(TARGET[8:10])
t_start = datetime.datetime(y, m, d).timestamp() * 1000
t_end = t_start + 86400000

with open(HISTORY) as f:
    lines = f.readlines()

sessions = {}
for line in lines:
    obj = json.loads(line)
    ts = obj.get("timestamp", 0)
    if t_start <= ts < t_end:
        sid = obj.get("sessionId", "")
        if not sid:
            continue
        proj = obj.get("project", "unknown")
        display = obj.get("display", "").strip()
        if not display:
            continue
        proj_name = proj.split("/")[-1] if "/" in proj else proj
        if sid not in sessions:
            sessions[sid] = {"project": proj_name, "project_path": proj, "messages": [], "first_ts": ts}
        sessions[sid]["messages"].append(display)
        if ts < sessions[sid]["first_ts"]:
            sessions[sid]["first_ts"] = ts

results = []
for sid, info in sessions.items():
    proj_dir = re.sub(r'[^a-zA-Z0-9]', '-', info["project_path"])
    session_file = os.path.join(PROJECTS_DIR, proj_dir, f"{sid}.jsonl")
    duration = "-"
    size_str = "-"
    start_time = datetime.datetime.fromtimestamp(info["first_ts"] / 1000).strftime("%H:%M")
    if os.path.exists(session_file):
        stat = os.stat(session_file)
        created = datetime.datetime.fromtimestamp(stat.st_birthtime)
        modified = datetime.datetime.fromtimestamp(stat.st_mtime)
        delta = modified - created
        hours, remainder = divmod(int(delta.total_seconds()), 3600)
        minutes = remainder // 60
        duration = f"{hours}h {minutes:02d}m"
        start_time = created.strftime("%H:%M")
        size_mb = stat.st_size / (1024 * 1024)
        size_str = f"{size_mb:.1f}MB"
    first_msg = info["messages"][0][:50].replace("|", "/").replace("\n", " ")
    results.append((start_time, info["project"], sid[:8], duration, size_str, first_msg, len(info["messages"])))

results.sort(key=lambda x: x[0])

print(f"## {TARGET} 세션 목록 ({len(results)}개 세션)\n")
print("| # | 프로젝트 | 세션 ID | 시작 | Duration | 크기 | 메시지 수 | 첫 메시지 |")
print("|---|----------|---------|------|----------|------|-----------|-----------|")
for i, (start, proj, sid, dur, size, msg, cnt) in enumerate(results, 1):
    print(f"| {i} | {proj} | {sid} | {start} | {dur} | {size} | {cnt} | {msg} |")
```

**실행 방법**: Bash 도구에서 `python3 -c '...'` 또는 `python3 << 'PYEOF' ... PYEOF` 형태로 위 스크립트를 실행합니다.

---

## show 커맨드

세션 ID prefix(8자 이상)를 받아 해당 세션의 상세 정보와 AI 요약을 제공합니다.

### 실행 절차

1. **세션 데이터 추출** — Bash로 python3 스크립트를 실행하여 메타데이터 + 대화 데이터 추출
2. **haiku 서브에이전트에 요약 위임** — Task 도구로 추출된 대화 데이터를 넘겨 AI 요약 생성
3. **결과 통합 출력** — 메타데이터 테이블 + AI 요약 + 사용자 메시지 목록

### Step 1: 세션 데이터 추출 스크립트 (SESSION_PREFIX 치환 필요)

```python
import json, os, datetime

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
HISTORY = os.path.expanduser("~/.claude/history.jsonl")
PREFIX = "{SESSION_PREFIX}"

# Find session file by prefix
matches = []
for dirpath, dirnames, filenames in os.walk(PROJECTS_DIR):
    for f in filenames:
        if f.startswith(PREFIX) and f.endswith(".jsonl"):
            matches.append(os.path.join(dirpath, f))

if not matches:
    print("ERROR: NO_MATCH")
    raise SystemExit(1)
if len(matches) > 1:
    print("ERROR: MULTI_MATCH")
    for m in matches:
        sid = os.path.basename(m).replace(".jsonl", "")
        proj_dir = os.path.basename(os.path.dirname(m))
        print(f"  {sid[:8]} | {proj_dir}")
    raise SystemExit(1)

session_file = matches[0]
sid = os.path.basename(session_file).replace(".jsonl", "")
proj_dir = os.path.basename(os.path.dirname(session_file))

# File metadata
stat = os.stat(session_file)
created = datetime.datetime.fromtimestamp(stat.st_birthtime)
modified = datetime.datetime.fromtimestamp(stat.st_mtime)
delta = modified - created
hours, remainder = divmod(int(delta.total_seconds()), 3600)
minutes = remainder // 60
size_mb = stat.st_size / (1024 * 1024)

# Parse session JSONL
with open(session_file) as f:
    lines = f.readlines()

git_branch = "unknown"
cwd = "unknown"
user_msgs = []
assistant_snippets = []
user_count = 0
asst_count = 0

for line in lines:
    obj = json.loads(line)
    t = obj.get("type")
    if t == "progress" and obj.get("gitBranch") and git_branch == "unknown":
        git_branch = obj["gitBranch"]
        cwd = obj.get("cwd", "unknown")
    elif t == "user":
        user_count += 1
        content = obj.get("message", {}).get("content", "")
        if isinstance(content, str) and content.strip():
            text = content.strip()[:200].replace("\n", " ")
            if not text.startswith("<"):
                user_msgs.append(text)
    elif t == "assistant":
        asst_count += 1
        content = obj.get("message", {}).get("content", "")
        if isinstance(content, list):
            texts = [b.get("text", "") for b in content if b.get("type") == "text"]
            snippet = " ".join(texts)[:100].replace("\n", " ")
        else:
            snippet = str(content)[:100].replace("\n", " ")
        if snippet.strip():
            assistant_snippets.append(snippet)

# Get history display messages
history_msgs = []
with open(HISTORY) as f:
    for line in f:
        obj = json.loads(line)
        if obj.get("sessionId") == sid:
            d = obj.get("display", "").strip()
            if d:
                history_msgs.append(d[:200])

# Output metadata
print("META_START")
print(f"session_id: {sid}")
print(f"project_dir: {proj_dir}")
print(f"cwd: {cwd}")
print(f"git_branch: {git_branch}")
print(f"start: {created.strftime('%Y-%m-%d %H:%M')}")
print(f"end: {modified.strftime('%Y-%m-%d %H:%M')}")
print(f"duration: {hours}h {minutes:02d}m")
print(f"user_messages: {user_count}")
print(f"assistant_messages: {asst_count}")
print(f"file_size: {size_mb:.1f}MB")
print("META_END")

# Output conversation data for AI summary (max ~4000 chars)
print("CONV_START")
total = 0
for u, a in zip(user_msgs, assistant_snippets):
    entry = f"U: {u}\nA: {a}\n"
    if total + len(entry) > 4000:
        break
    print(entry)
    total += len(entry)
print("CONV_END")

# Output history display messages
print("HISTORY_START")
for i, m in enumerate(history_msgs, 1):
    print(f"{i}. {m}")
print("HISTORY_END")
```

### Step 2: haiku 서브에이전트로 요약 생성

추출된 CONV_START~CONV_END 사이의 대화 데이터를 haiku 서브에이전트에 전달합니다.

**Task 호출 파라미터:**

| 파라미터 | 값 |
|---------|-----|
| description | "세션 요약 생성" |
| subagent_type | "general-purpose" |
| model | "haiku" |

**프롬프트 (변수 치환 필요):**

```
아래 Claude Code 세션의 대화 내용을 분석하여 요약해주세요.
코드를 작성하지 말고 분석만 수행하세요.

## 세션 정보
- 프로젝트: {PROJECT_DIR}
- 기간: {START} ~ {END} ({DURATION})

## 대화 내용 (U=사용자, A=어시스턴트)
{CONV_DATA}

## 출력 형식
### 요약
- 이 세션에서 수행한 작업을 3-5개 항목으로 정리
- 각 항목은 "무엇을 했는지"를 1줄로 서술

### 주요 결정사항
- 세션 중 내려진 기술적 결정이 있으면 기록 (없으면 "없음")

### 미완료 작업
- 세션에서 시작했으나 완료되지 않은 작업이 있으면 기록 (없으면 "없음")
```

### Step 3: 결과 통합 출력

메인 에이전트가 아래 형식으로 메타데이터 + AI 요약 + 사용자 메시지를 조합하여 출력합니다:

```markdown
## 세션 상세: {SESSION_ID_SHORT}...

| 항목 | 값 |
|------|-----|
| 프로젝트 | {PROJECT_DIR} |
| 경로 | {CWD} |
| Git Branch | {GIT_BRANCH} |
| 시작 | {START} |
| 종료 | {END} |
| Duration | {DURATION} |
| 메시지 수 | User {USER_COUNT} / Assistant {ASST_COUNT} |
| 파일 크기 | {FILE_SIZE} |

### AI 요약
{HAIKU_SUBAGENT_RESULT}

### 사용자 메시지 목록
{HISTORY_MESSAGES}
```

---

## 에러 처리

- `history.jsonl` 파일 없음 → "~/.claude/history.jsonl 파일을 찾을 수 없습니다" 출력
- `show`에서 세션 ID prefix 매칭 0건 → "해당 prefix로 시작하는 세션을 찾을 수 없습니다" 출력
- `show`에서 세션 ID prefix 매칭 2건 이상 → 후보 목록(세션ID + 프로젝트) 표시 후 재선택 요청
- 세션 JSONL 파일 접근 불가 → "세션 파일을 읽을 수 없습니다" 출력
