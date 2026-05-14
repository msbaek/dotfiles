---
argument-hint: "[project-path] [--last N]"
description: "최근 sub-agent 호출에서 실제 사용된 모델을 확인 (skill/command의 model 설정이 실제로 적용됐는지 검증)"
---

# Sub-agent Model 검증 - $ARGUMENTS

최근 sub-agent JSONL 파일을 읽어 실제 API 호출에 사용된 모델을 보고한다.

## 실행 절차

아래 Python 스크립트를 Bash로 직접 실행하고 결과를 사용자에게 보고한다.

### 1. 프로젝트 경로 결정

`$ARGUMENTS`에 경로가 있으면 그 경로를 사용, 없으면 현재 working directory를 기준으로 Claude 프로젝트 경로를 유추한다:

```bash
# working directory → Claude 프로젝트 키 변환
# /Users/msbaek/foo/bar → -Users-msbaek-foo-bar
python3 -c "
import os
cwd = os.getcwd()
key = cwd.replace('/', '-').lstrip('-')
print(f'/Users/msbaek/.claude/projects/-{key}')
"
```

### 2. Sub-agent JSONL 조회 및 모델 추출

```bash
python3 << 'EOF'
import json, os, glob
from datetime import datetime

# $ARGUMENTS에서 --last N 파싱 (기본 10)
last_n = 10

project_root = "/Users/msbaek/.claude/projects"
pattern = f"{project_root}/*/subagents/agent-*.jsonl"

files = glob.glob(pattern, recursive=False)
if not files:
    # 중첩 구조도 시도
    pattern2 = f"{project_root}/*/*/subagents/agent-*.jsonl"
    files = glob.glob(pattern2)

# 수정 시간 기준 정렬
files.sort(key=lambda p: os.path.getmtime(p), reverse=True)
files = files[:last_n]

if not files:
    print("sub-agent JSONL 파일을 찾을 수 없습니다.")
else:
    print(f"{'파일 (agent-ID)':<30} {'수정시각':<20} {'모델'}")
    print("-" * 75)
    for path in files:
        models = set()
        try:
            with open(path) as f:
                for line in f:
                    try:
                        d = json.loads(line)
                        m = d.get('model') or (d.get('message') or {}).get('model')
                        if m:
                            models.add(m)
                    except:
                        pass
        except:
            models = {'(읽기 실패)'}

        mtime = datetime.fromtimestamp(os.path.getmtime(path)).strftime('%m-%d %H:%M:%S')
        agent_id = os.path.basename(path).replace('agent-', '').replace('.jsonl', '')[:16]
        model_str = ', '.join(sorted(models)) if models else '(모델 정보 없음)'
        print(f"{agent_id:<30} {mtime:<20} {model_str}")
EOF
```

### 3. 결과 포맷

출력 결과를 그대로 코드블록으로 감싸서 사용자에게 보여준다. 추가로:
- `claude-sonnet-*` → ✅ sonnet
- `claude-opus-*`   → ⚠️ opus (예상과 다를 수 있음)
- `claude-haiku-*`  → ℹ️ haiku

## 옵션

- `--last N`: 최근 N개 sub-agent 파일 확인 (기본 10)
- `[project-path]`: 특정 vault/프로젝트 경로 지정 (기본: 전체)
