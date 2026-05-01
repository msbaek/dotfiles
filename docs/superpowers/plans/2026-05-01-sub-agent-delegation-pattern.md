# Sub-agent Delegation Pattern Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spec `docs/superpowers/specs/2026-05-01-sub-agent-delegation-pattern-design.md`에 정의된 분류 매트릭스대로 38 파일에 sub-agent 위임 패턴(변형 A/B/C) 또는 인터랙티브 정리(model 제거 + 주석)를 적용하고, 표준 템플릿 1개를 신규 생성한다. 9 commits로 분리하여 rollback-friendly 상태 유지.

**Architecture:** 신규 `~/.claude/templates/delegation.md`에 4가지 변형(A/B/C/D) boilerplate를 단일 source-of-truth로 정의. 각 호출 파일(commands/skills)은 `## 실행 모델 (필수)` 섹션에 변형 reference + 파일별 args/options만 명시. 인터랙티브 파일은 frontmatter `model:` 라인 제거 + `<!-- Execution: interactive (main context) -->` 주석 추가.

**Tech Stack:** Markdown, YAML frontmatter, GNU Stow (symlink 배포), bash + ripgrep + awk (검증).

---

## File Structure

### 신규 (1개)

| 파일 | 책임 |
|------|------|
| `dotfiles/.claude/templates/delegation.md` | 4가지 위임 변형(A/B/C/D) 표준 boilerplate. 다른 모든 호출 파일이 reference하는 단일 source-of-truth. |

### 수정 (38개)

dotfiles repo 기준 경로:
- Commands: `dotfiles/.claude/commands/{*,obsidian/*}.md`
- Skills: `dotfiles/.claude/skills/<name>/SKILL.md`

Commands 24개 + Skills 14개. 분류는 spec Section 4 참조.

### 검증 보조 (생성하지 않음)

검증은 ad-hoc shell command로 수행 (별도 스크립트 파일 만들지 않음 — YAGNI).

---

## 표준 Boilerplate (재사용)

### 변형 A/B/C 적용 시 — 호출 파일에 삽입할 섹션 (frontmatter 종료 직후, `# 제목` 다음 본문 시작 전)

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 <X> 적용**
(model="<MODEL>", run_in_background=<BG>, args=$ARGUMENTS, 옵션=<OPTIONS>)

main context에서 직접 실행 금지.
```

치환 변수:
- `<X>`: A | B | C
- `<MODEL>`: sonnet (A, C) | haiku (B)
- `<BG>`: false (A, B) | true (C)
- `<OPTIONS>`: 해당 파일의 `argument-hint` frontmatter에서 옵션 추출 (예: `--dry-run`, `--recursive`). 옵션이 없으면 `옵션=없음`으로 표기.

### 인터랙티브(I) 적용 시 — frontmatter `model:` 라인 제거 + 헤더에 주석 추가

frontmatter 종료(`---`) 직후, `# 제목` 다음에 삽입:

```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```

---

## Task 1: 표준 템플릿 신규 생성

**Files:**
- Create: `dotfiles/.claude/templates/delegation.md`

- [x] **Step 1: 디렉토리 생성**

```bash
mkdir -p ~/dotfiles/.claude/templates
```

- [x] **Step 2: `delegation.md` 작성**

파일 내용 전체:

````markdown
# Sub-agent 위임 패턴 (Single Source of Truth)

이 문서는 `~/.claude/commands/`와 `~/.claude/skills/` 하위 사용자 작성 파일에서 참조하는 sub-agent 위임 표준 boilerplate를 정의한다.

## 왜 sub-agent 위임이 필요한가

slash command/skill의 frontmatter `model:` 필드는 **main context에서 호출 시 무시된다** (사용자 발견 규약, `~/.claude/CLAUDE.md` 참조). 즉, `model: sonnet`이라고 적어둬도 현재 세션 모델(예: Opus)로 그대로 실행되어 비용 최적화가 안 된다.

해결책: main context에서 sub-agent를 호출하면서 `model: "sonnet"` 또는 `"haiku"`를 **명시적으로** 전달한다.

## 변형 A — 동기 + Sonnet (가장 흔한 케이스)

용도: 텍스트 변환·요약·분석·생성. 사용자가 결과를 동기적으로 받음.

호출 방법:
- Tool: `Agent` (Task)
- `subagent_type: "general-purpose"`
- `model: "sonnet"` — main context 모델과 무관하게 sonnet-4.6 고정 (비용 최적화)
- `run_in_background: false` — 사용자가 결과를 동기적으로 받음
- `prompt`: 호출 파일의 "작업 프로세스" 전체 + `$ARGUMENTS` 값 + 파일 경로 + 옵션 플래그를 그대로 전달

sub-agent 결과를 받으면 호출 파일의 "작업 결과 형식"에 맞춰 사용자에게 보고. 단, sub-agent 위임 외의 추가 분석/실행은 하지 말 것.

## 변형 B — 동기 + Haiku (단순 변환·조회)

용도: 포맷 변환, 단순 분류, 도구 호출 wrapper, CLI 결과 보고. 추론 깊이가 얕은 작업.

변형 A와 동일하되 `model: "haiku"`.

## 변형 C — 백그라운드 + Sonnet (장기 작업)

용도: URL → 번역/요약/문서 생성처럼 수 분 이상 걸리는 작업.

호출 방법:
- Tool: `Agent` (Task)
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `run_in_background: true`
- progress 파일을 `.claude/summarize-progress/` (또는 호출 파일 지정 디렉토리)에 생성 후 즉시 사용자에게 알림
- 사용자는 `obsidian-jobs` 같은 상태 조회 명령으로 진행 확인

## 변형 D — 백그라운드 + Haiku

현재 사용처 없음. 정의만 두고 미래 작업에서 채택.

변형 C와 동일하되 `model: "haiku"`.

## 호출 파일에서의 reference 형식

각 command/skill은 frontmatter 종료 직후 `## 실행 모델 (필수)` 섹션을 두고 변형과 변수를 명시한다:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=$ARGUMENTS, 옵션=`--dry-run`, `--recursive`)

main context에서 직접 실행 금지.
```

## 인터랙티브 작업은 위임 안 함

multi-turn 대화로 진행되는 작업(예: 사용자 결정을 받아가며 정리하는 명령)은 sub-agent 위임 안 함. main context에서 그대로 실행한다. 이 경우 frontmatter `model:` 라인은 의미가 없으므로 제거하고, 헤더에 다음 주석을 둔다:

```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```
````

- [x] **Step 3: 검증**

```bash
test -f ~/dotfiles/.claude/templates/delegation.md && echo OK
grep -c "^## 변형" ~/dotfiles/.claude/templates/delegation.md
```

Expected: `OK` 출력 + `^## 변형` 4건 (A/B/C/D).

- [x] **Step 4: stow 적용 확인**

```bash
cd ~/dotfiles && stow .
test -L ~/.claude/templates/delegation.md && readlink ~/.claude/templates/delegation.md
```

Expected: symlink가 `~/dotfiles/.claude/templates/delegation.md` 가리킴. (이미 templates 디렉토리가 stow 관리 안 되어 있다면 새로 symlink 생성됨.)

- [x] **Step 5: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
feat(claude/templates): sub-agent delegation 표준 템플릿 추가

frontmatter `model:` 필드가 main context에서 무시되는 문제를 해결하기 위해
사용자 작성 commands/skills가 참조할 단일 source-of-truth 작성.

변형 A(동기+sonnet), B(동기+haiku), C(백그라운드+sonnet), D(미래용) 정의.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/templates/delegation.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 2: Commands 변형 A 일괄 적용 (10개)

**Files (수정):**

| # | 파일 | argument-hint에서 추출할 옵션 |
|---|------|------------------------------|
| 1 | `dotfiles/.claude/commands/commit.md` | `--amend`, `--push`, `--no-verify` |
| 2 | `dotfiles/.claude/commands/wrap-up.md` | (frontmatter 확인) |
| 3 | `dotfiles/.claude/commands/meeting-minutes.md` | (frontmatter 확인) |
| 4 | `dotfiles/.claude/commands/check-security.md` | (frontmatter 확인) |
| 5 | `dotfiles/.claude/commands/obsidian/batch-process.md` | (frontmatter 확인) |
| 6 | `dotfiles/.claude/commands/obsidian/create-presentation.md` | (frontmatter 확인) |
| 7 | `dotfiles/.claude/commands/obsidian/related-contents.md` | (frontmatter 확인) |
| 8 | `dotfiles/.claude/commands/obsidian/translate-article.md` | (frontmatter 확인) |
| 9 | `dotfiles/.claude/commands/obsidian/translate-youtube.md` | (frontmatter 확인) |
| 10 | `dotfiles/.claude/commands/obsidian/weekly-social-posts.md` | (frontmatter 확인) |

- [x] **Step 1: 각 파일의 argument-hint 일괄 추출**

```bash
cd ~/dotfiles
for f in .claude/commands/commit.md \
         .claude/commands/wrap-up.md \
         .claude/commands/meeting-minutes.md \
         .claude/commands/check-security.md \
         .claude/commands/obsidian/batch-process.md \
         .claude/commands/obsidian/create-presentation.md \
         .claude/commands/obsidian/related-contents.md \
         .claude/commands/obsidian/translate-article.md \
         .claude/commands/obsidian/translate-youtube.md \
         .claude/commands/obsidian/weekly-social-posts.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^argument-hint:/{print}' "$f"
done
```

이 출력으로 각 파일의 옵션 변수를 결정. 옵션이 없는 파일은 reference 라인에서 `옵션=없음`으로 표기.

- [x] **Step 2: 각 파일에 `## 실행 모델 (필수)` 섹션 삽입**

위치: frontmatter 종료(`---`) 직후, `# 제목 - $ARGUMENTS` 다음, `## 작업 프로세스`(또는 그에 준하는 첫 본문 헤더) 직전.

각 파일에 삽입할 정확한 텍스트 (argument-hint 옵션은 위 Step 1 결과로 치환):

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=$ARGUMENTS, 옵션=<argument-hint에서 추출>)

main context에서 직접 실행 금지.
```

`commit.md` 예시 (옵션 치환 완료):
```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=$ARGUMENTS, 옵션=`--amend`, `--push`, `--no-verify`)

main context에서 직접 실행 금지.
```

도구: Edit tool (10 파일 각각). old_string에는 frontmatter 종료부터 `## 작업 프로세스` 라인까지 포함하여 uniqueness 보장.

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/commands/commit.md \
         .claude/commands/wrap-up.md \
         .claude/commands/meeting-minutes.md \
         .claude/commands/check-security.md \
         .claude/commands/obsidian/batch-process.md \
         .claude/commands/obsidian/create-presentation.md \
         .claude/commands/obsidian/related-contents.md \
         .claude/commands/obsidian/translate-article.md \
         .claude/commands/obsidian/translate-youtube.md \
         .claude/commands/obsidian/weekly-social-posts.md; do
  if grep -q "templates/delegation.md 변형 A" "$f"; then
    echo "OK $f"
  else
    echo "FAIL $f"
  fi
done
```

Expected: 10개 전부 `OK`. `FAIL`이 하나라도 있으면 해당 파일 재수정.

- [x] **Step 3 (Task 2): 변경 검증 완료**

- [x] **Step 4: stow 적용 + symlink 무결성**

```bash
cd ~/dotfiles && stow . && echo "stow OK"
ls -la ~/.claude/commands/commit.md
```

Expected: symlink 정상.

- [x] **Step 5: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/commands): 동기+sonnet sub-agent 위임 패턴 적용

10개 commands에 변형 A boilerplate reference 추가:
commit, wrap-up, meeting-minutes, check-security,
obsidian/{batch-process, create-presentation, related-contents,
translate-article, translate-youtube, weekly-social-posts}

각 파일의 frontmatter argument-hint 옵션을 reference 라인에 명시.
main context 실행 시 sonnet-4.6 sub-agent로 위임되도록 명시화.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/commands/commit.md \
        .claude/commands/wrap-up.md \
        .claude/commands/meeting-minutes.md \
        .claude/commands/check-security.md \
        .claude/commands/obsidian/batch-process.md \
        .claude/commands/obsidian/create-presentation.md \
        .claude/commands/obsidian/related-contents.md \
        .claude/commands/obsidian/translate-article.md \
        .claude/commands/obsidian/translate-youtube.md \
        .claude/commands/obsidian/weekly-social-posts.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 3: Commands 변형 B 일괄 적용 (5개)

**Files (수정):**

| # | 파일 |
|---|------|
| 1 | `dotfiles/.claude/commands/conventional-review.md` |
| 2 | `dotfiles/.claude/commands/markitdown-convert.md` |
| 3 | `dotfiles/.claude/commands/skills-audit.md` |
| 4 | `dotfiles/.claude/commands/skills-catalog.md` |
| 5 | `dotfiles/.claude/commands/obsidian/vault-query.md` |

- [x] **Step 1: argument-hint 추출**

```bash
cd ~/dotfiles
for f in .claude/commands/conventional-review.md \
         .claude/commands/markitdown-convert.md \
         .claude/commands/skills-audit.md \
         .claude/commands/skills-catalog.md \
         .claude/commands/obsidian/vault-query.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^argument-hint:/{print}' "$f"
done
```

- [x] **Step 2: 각 파일에 `## 실행 모델 (필수)` 섹션 삽입 (변형 B)**

삽입 텍스트 (옵션 치환):

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 B 적용**
(model="haiku", run_in_background=false, args=$ARGUMENTS, 옵션=<argument-hint에서 추출>)

main context에서 직접 실행 금지.
```

도구: Edit tool. 위치는 Task 2 Step 2와 동일 규칙.

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/commands/conventional-review.md \
         .claude/commands/markitdown-convert.md \
         .claude/commands/skills-audit.md \
         .claude/commands/skills-catalog.md \
         .claude/commands/obsidian/vault-query.md; do
  if grep -q "templates/delegation.md 변형 B" "$f"; then
    echo "OK $f"
  else
    echo "FAIL $f"
  fi
done
```

Expected: 5개 전부 `OK`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/commands): 동기+haiku sub-agent 위임 패턴 적용

5개 commands에 변형 B boilerplate reference 추가:
conventional-review, markitdown-convert, skills-audit, skills-catalog,
obsidian/vault-query

단순 변환/조회 작업이므로 haiku로 위임. 비용 최적화.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/commands/conventional-review.md \
        .claude/commands/markitdown-convert.md \
        .claude/commands/skills-audit.md \
        .claude/commands/skills-catalog.md \
        .claude/commands/obsidian/vault-query.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 4: Commands 변형 C 일괄 적용 (3개)

**Files (수정):**

| # | 파일 | 비고 |
|---|------|------|
| 1 | `dotfiles/.claude/commands/coffee-time.md` | 신규 백그라운드 위임 |
| 2 | `dotfiles/.claude/commands/obsidian/summarize-article.md` | shared-rules.md에서 백그라운드 사용 중 — reference 추가만 |
| 3 | `dotfiles/.claude/commands/obsidian/summarize-youtube.md` | 동상 |

- [x] **Step 1: 각 파일 현재 상태 확인 (백그라운드 호출 코드가 본문에 있는지)**

```bash
cd ~/dotfiles
for f in .claude/commands/coffee-time.md \
         .claude/commands/obsidian/summarize-article.md \
         .claude/commands/obsidian/summarize-youtube.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^argument-hint:/{print}' "$f"
  grep -c "run_in_background" "$f" || true
done
```

`run_in_background` count가 0이면 본문 어디에도 백그라운드 명시 없음 (coffee-time 가능성).
1+이면 이미 명시됨 (summarize-* 가능성).

- [x] **Step 2: 각 파일에 `## 실행 모델 (필수)` 섹션 삽입 (변형 C)**

삽입 텍스트:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 C 적용**
(model="sonnet", run_in_background=true, args=$ARGUMENTS, 옵션=<argument-hint에서 추출>)

main context에서 직접 실행 금지. 즉시 progress 파일 생성 후 사용자 알림.
```

`summarize-article.md` / `summarize-youtube.md`의 경우 본문에 이미 `obsidian/shared-rules.md` 백그라운드 모드 reference가 있을 수 있음 — 그 섹션은 그대로 두고 `## 실행 모델 (필수)`만 frontmatter 직후에 추가 (중복 정보지만 reference 단일화 목적).

`coffee-time.md`의 경우 사용자가 이번에 새로 백그라운드로 결정한 명령 — 본문에 progress 파일 처리 로직이 없을 가능성 높음. 본문 변경은 이번 task 범위 밖. reference만 추가하고, 추후 행동 검증에서 동작 안 하면 별도 task로 본문 보강.

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/commands/coffee-time.md \
         .claude/commands/obsidian/summarize-article.md \
         .claude/commands/obsidian/summarize-youtube.md; do
  if grep -q "templates/delegation.md 변형 C" "$f"; then
    echo "OK $f"
  else
    echo "FAIL $f"
  fi
done
```

Expected: 3개 전부 `OK`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/commands): 백그라운드+sonnet 위임 패턴 명시

3개 commands에 변형 C boilerplate reference 추가:
coffee-time (신규 백그라운드 결정), obsidian/{summarize-article, summarize-youtube}
(이미 백그라운드 동작 중 — reference 단일화)

장기 작업이므로 progress 파일 + 백그라운드 sub-agent 위임.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/commands/coffee-time.md \
        .claude/commands/obsidian/summarize-article.md \
        .claude/commands/obsidian/summarize-youtube.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 5: Commands 인터랙티브 정리 (6개)

**Files (수정):**

| # | 파일 |
|---|------|
| 1 | `dotfiles/.claude/commands/askUserQuestion.md` |
| 2 | `dotfiles/.claude/commands/code-review-walkthrough.md` |
| 3 | `dotfiles/.claude/commands/my-developer.md` |
| 4 | `dotfiles/.claude/commands/project-overview.md` |
| 5 | `dotfiles/.claude/commands/skills-curate.md` |
| 6 | `dotfiles/.claude/commands/update-claude-md.md` |

- [x] **Step 1: 각 파일의 frontmatter `model:` 라인 제거**

도구: Edit tool. old_string에 `model: <value>\n` 한 줄 단독 매칭, new_string에 빈 문자열.

각 파일의 현재 model 값 확인:
```bash
cd ~/dotfiles
for f in .claude/commands/askUserQuestion.md \
         .claude/commands/code-review-walkthrough.md \
         .claude/commands/my-developer.md \
         .claude/commands/project-overview.md \
         .claude/commands/skills-curate.md \
         .claude/commands/update-claude-md.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^model:/{print}' "$f"
done
```

각 파일에 대해 Edit:
- old_string: `model: sonnet\n` (또는 출력에서 확인된 값)
- new_string: (빈 문자열)

- [x] **Step 2: 각 파일에 인터랙티브 주석 추가**

위치: frontmatter 종료(`---`) 직후, `# 제목` 라인 다음 빈 줄에 삽입.

삽입 텍스트:
```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```

도구: Edit tool. old_string에 `# <제목>\n\n` 매칭, new_string에 `# <제목>\n\n<주석>\n\n`.

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/commands/askUserQuestion.md \
         .claude/commands/code-review-walkthrough.md \
         .claude/commands/my-developer.md \
         .claude/commands/project-overview.md \
         .claude/commands/skills-curate.md \
         .claude/commands/update-claude-md.md; do
  has_model=$(awk '/^---$/{f=!f; next} f && /^model:/{print "yes"}' "$f")
  has_comment=$(grep -c "Execution: interactive" "$f")
  echo "$f model=${has_model:-no} comment=$has_comment"
done
```

Expected: 6개 전부 `model=no comment=1`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/commands): 인터랙티브 명령 model 필드 제거 + 주석

6개 인터랙티브 commands에서 의미 없는 frontmatter `model:` 라인 제거하고
main context 실행 의도를 명시한 주석 추가:
askUserQuestion, code-review-walkthrough, my-developer, project-overview,
skills-curate, update-claude-md

multi-turn 대화로 진행되는 작업은 sub-agent 위임 시 흐름이 끊기므로
main context에서 그대로 실행. frontmatter `model:` 필드는 어차피 무시됨.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/commands/askUserQuestion.md \
        .claude/commands/code-review-walkthrough.md \
        .claude/commands/my-developer.md \
        .claude/commands/project-overview.md \
        .claude/commands/skills-curate.md \
        .claude/commands/update-claude-md.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 6: Skills 변형 A 일괄 적용 (4개)

**Files (수정):**

| # | 파일 |
|---|------|
| 1 | `dotfiles/.claude/skills/architecture-diagram/SKILL.md` |
| 2 | `dotfiles/.claude/skills/graphify/SKILL.md` |
| 3 | `dotfiles/.claude/skills/capture-research/SKILL.md` |
| 4 | `dotfiles/.claude/skills/claude-code-release-tracker/SKILL.md` |

- [x] **Step 1: 각 파일 frontmatter 확인 (현재 model 값 + name)**

```bash
cd ~/dotfiles
for f in .claude/skills/architecture-diagram/SKILL.md \
         .claude/skills/graphify/SKILL.md \
         .claude/skills/capture-research/SKILL.md \
         .claude/skills/claude-code-release-tracker/SKILL.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^(model|name):/{print}' "$f"
done
```

Skills는 `argument-hint`가 없으므로 옵션은 `옵션=없음`로 표기. 단 description에서 트리거 문구가 인자 형태일 수 있어 SKILL.md 본문에서 사용 패턴 확인.

- [x] **Step 2: 각 파일에 `## 실행 모델 (필수)` 섹션 삽입**

위치: frontmatter 종료(`---`) 직후, `# 제목` 다음, 첫 본문 섹션 직전.

삽입 텍스트:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=skill 호출 인자, 옵션=없음)

main context에서 직접 실행 금지.
```

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/skills/architecture-diagram/SKILL.md \
         .claude/skills/graphify/SKILL.md \
         .claude/skills/capture-research/SKILL.md \
         .claude/skills/claude-code-release-tracker/SKILL.md; do
  if grep -q "templates/delegation.md 변형 A" "$f"; then
    echo "OK $f"
  else
    echo "FAIL $f"
  fi
done
```

Expected: 4개 전부 `OK`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/skills): 동기+sonnet sub-agent 위임 패턴 적용

4개 skills에 변형 A boilerplate reference 추가:
architecture-diagram, graphify, capture-research, claude-code-release-tracker

생성/변환 작업이 sonnet 적합. main context 실행 시 sub-agent로 위임 명시.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/skills/architecture-diagram/SKILL.md \
        .claude/skills/graphify/SKILL.md \
        .claude/skills/capture-research/SKILL.md \
        .claude/skills/claude-code-release-tracker/SKILL.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 7: Skills 변형 B 일괄 적용 (6개)

**Files (수정):**

| # | 파일 |
|---|------|
| 1 | `dotfiles/.claude/skills/agf/SKILL.md` |
| 2 | `dotfiles/.claude/skills/recall/SKILL.md` |
| 3 | `dotfiles/.claude/skills/vis/SKILL.md` |
| 4 | `dotfiles/.claude/skills/vis-backlink-status/SKILL.md` |
| 5 | `dotfiles/.claude/skills/obsidian-jobs/SKILL.md` |
| 6 | `dotfiles/.claude/skills/extract-sql-log/SKILL.md` |

- [x] **Step 1: 각 파일 frontmatter 확인**

```bash
cd ~/dotfiles
for f in .claude/skills/agf/SKILL.md \
         .claude/skills/recall/SKILL.md \
         .claude/skills/vis/SKILL.md \
         .claude/skills/vis-backlink-status/SKILL.md \
         .claude/skills/obsidian-jobs/SKILL.md \
         .claude/skills/extract-sql-log/SKILL.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^(model|name):/{print}' "$f"
done
```

- [x] **Step 2: 각 파일에 `## 실행 모델 (필수)` 섹션 삽입 (변형 B)**

삽입 텍스트:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 B 적용**
(model="haiku", run_in_background=false, args=skill 호출 인자, 옵션=없음)

main context에서 직접 실행 금지.
```

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/skills/agf/SKILL.md \
         .claude/skills/recall/SKILL.md \
         .claude/skills/vis/SKILL.md \
         .claude/skills/vis-backlink-status/SKILL.md \
         .claude/skills/obsidian-jobs/SKILL.md \
         .claude/skills/extract-sql-log/SKILL.md; do
  if grep -q "templates/delegation.md 변형 B" "$f"; then
    echo "OK $f"
  else
    echo "FAIL $f"
  fi
done
```

Expected: 6개 전부 `OK`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/skills): 동기+haiku sub-agent 위임 패턴 적용

6개 skills에 변형 B boilerplate reference 추가:
agf, recall, vis, vis-backlink-status, obsidian-jobs, extract-sql-log

CLI wrapper / 단순 조회 / 로그 파싱 작업이 haiku 적합. 비용 최적화.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/skills/agf/SKILL.md \
        .claude/skills/recall/SKILL.md \
        .claude/skills/vis/SKILL.md \
        .claude/skills/vis-backlink-status/SKILL.md \
        .claude/skills/obsidian-jobs/SKILL.md \
        .claude/skills/extract-sql-log/SKILL.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 8: Skills 인터랙티브 정리 (4개)

**Files (수정):**

| # | 파일 |
|---|------|
| 1 | `dotfiles/.claude/skills/brunch-writer/SKILL.md` |
| 2 | `dotfiles/.claude/skills/write-in-my-voice/SKILL.md` |
| 3 | `dotfiles/.claude/skills/find-session/SKILL.md` |
| 4 | `dotfiles/.claude/skills/session-handoff/SKILL.md` |

- [x] **Step 1: 각 파일 frontmatter 확인**

```bash
cd ~/dotfiles
for f in .claude/skills/brunch-writer/SKILL.md \
         .claude/skills/write-in-my-voice/SKILL.md \
         .claude/skills/find-session/SKILL.md \
         .claude/skills/session-handoff/SKILL.md; do
  echo "=== $f ==="
  awk '/^---$/{f=!f; next} f && /^model:/{print}' "$f"
done
```

`model:` 라인이 있는 파일만 제거 대상. 없는 파일은 Step 2 만 적용.

- [x] **Step 2: `model:` 라인 제거 (있는 파일만) + 인터랙티브 주석 추가**

각 파일에 대해:
- 있으면 frontmatter `model:` 라인 Edit으로 제거
- frontmatter 직후 `# 제목` 다음 빈 줄에 주석 삽입:

```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```

- [x] **Step 3: 변경 검증**

```bash
cd ~/dotfiles
for f in .claude/skills/brunch-writer/SKILL.md \
         .claude/skills/write-in-my-voice/SKILL.md \
         .claude/skills/find-session/SKILL.md \
         .claude/skills/session-handoff/SKILL.md; do
  has_model=$(awk '/^---$/{f=!f; next} f && /^model:/{print "yes"}' "$f")
  has_comment=$(grep -c "Execution: interactive" "$f")
  echo "$f model=${has_model:-no} comment=$has_comment"
done
```

Expected: 4개 전부 `model=no comment=1`.

- [x] **Step 4: Commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
refactor(claude/skills): 인터랙티브 skill model 필드 제거 + 주석

4개 인터랙티브 skills 정리:
brunch-writer, write-in-my-voice, find-session, session-handoff

multi-turn 대화 유지를 위해 main context에서 그대로 실행. frontmatter
`model:` 필드는 어차피 무시되므로 제거하고 의도를 주석으로 명시.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add .claude/skills/brunch-writer/SKILL.md \
        .claude/skills/write-in-my-voice/SKILL.md \
        .claude/skills/find-session/SKILL.md \
        .claude/skills/session-handoff/SKILL.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 9: 최종 검증 + ai-learnings 업데이트

- [x] **Step 1: 전체 변경 파일 일괄 검증 — 변형 A/B/C reference 존재**

```bash
cd ~/dotfiles
echo "=== 변형 A (commands 10 + skills 4 = 14 expected) ==="
rg -l "templates/delegation.md 변형 A" .claude/commands .claude/skills | wc -l

echo "=== 변형 B (commands 5 + skills 6 = 11 expected) ==="
rg -l "templates/delegation.md 변형 B" .claude/commands .claude/skills | wc -l

echo "=== 변형 C (commands 3 expected) ==="
rg -l "templates/delegation.md 변형 C" .claude/commands .claude/skills | wc -l
```

Expected: 14 / 11 / 3.

- [x] **Step 2: 인터랙티브 파일 검증 (commands 6 + skills 4 = 10 expected)**

```bash
cd ~/dotfiles
echo "=== 인터랙티브 주석 ==="
rg -l "Execution: interactive" .claude/commands .claude/skills | wc -l
```

Expected: 10.

- [x] **Step 3: 인터랙티브 파일에 model 라인 부재 확인**

```bash
cd ~/dotfiles
for f in .claude/commands/askUserQuestion.md \
         .claude/commands/code-review-walkthrough.md \
         .claude/commands/my-developer.md \
         .claude/commands/project-overview.md \
         .claude/commands/skills-curate.md \
         .claude/commands/update-claude-md.md \
         .claude/skills/brunch-writer/SKILL.md \
         .claude/skills/write-in-my-voice/SKILL.md \
         .claude/skills/find-session/SKILL.md \
         .claude/skills/session-handoff/SKILL.md; do
  if awk '/^---$/{f=!f; next} f && /^model:/{exit 0} END{exit 1}' "$f"; then
    echo "FAIL (model still present) $f"
  else
    echo "OK $f"
  fi
done
```

Expected: 10개 전부 `OK`.

- [x] **Step 4: stow 무결성 + symlink 확인**

```bash
cd ~/dotfiles && stow . && echo "stow OK"
test -L ~/.claude/templates/delegation.md && echo "templates OK"
test -L ~/.claude/commands/commit.md && echo "commit symlink OK"
test -L ~/.claude/skills/agf/SKILL.md && echo "agf symlink OK"
```

Expected: 모든 echo 출력.

- [x] **Step 5: Frontmatter YAML 무결성 (변경된 모든 파일)**

```bash
cd ~/dotfiles
fail=0
for f in $(rg -l "templates/delegation.md|Execution: interactive" .claude/commands .claude/skills); do
  awk '/^---$/{c++; if(c==2){exit 0}} END{if(c!=2)exit 1}' "$f" || { echo "FAIL frontmatter $f"; fail=1; }
done
[ $fail -eq 0 ] && echo "all frontmatter OK"
```

Expected: `all frontmatter OK`. 실패 시 해당 파일 frontmatter 재확인.

- [x] **Step 6: ai-learnings.md 업데이트**

`~/dotfiles/ai-learnings.md` 상단에 다음 항목 추가 (head 20 안에 들도록):

```markdown
## Sub-agent 위임 패턴 일괄 적용 (2026-05-01)

### 결정
- frontmatter `model:` 필드는 main context 호출 시 무시됨 → 비용 의도 있으면 sub-agent 경유 필수
- 표준 boilerplate를 `~/.claude/templates/delegation.md` 단일 source-of-truth로 정의
- 변형 A(동기+sonnet) / B(동기+haiku) / C(백그라운드+sonnet) / D(미래용)
- 인터랙티브 작업은 위임 안 함 — main context 유지 + `<!-- Execution: interactive -->` 주석

### 적용
- 38 파일(commands 24 + skills 14) + templates 1개 신규
- spec: `docs/superpowers/specs/2026-05-01-sub-agent-delegation-pattern-design.md`
- plan: `docs/superpowers/plans/2026-05-01-sub-agent-delegation-pattern.md`

### 후속
- N 그룹 reference doc skills의 `model:` 정리는 별도 task로
- 행동 검증은 일상 사용 중 token usage 모니터링
```

- [x] **Step 7: Final commit**

```bash
cd ~/dotfiles
cat > /tmp/commit-msg.txt << 'EOF'
docs(learnings): sub-agent 위임 패턴 일괄 적용 학습 기록

38 파일 변경 (commands 24 + skills 14) + templates/delegation.md 신규.
spec/plan 위치와 후속 작업 정리.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
git add ai-learnings.md
git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

---

## Task 10: (선택) 행동 검증 — 사용자가 일상에서 테스트

> **Status: ongoing** (Tasks 1-9 완료 2026-05-01. Task 10은 일상 사용 중 지속 모니터링)

이 task는 자동화 불가. 사용자가 평소 명령 실행하면서 다음을 확인:

- [ ] `/commit` 실행 시 sub-agent dispatch 발생하는지 (token usage 또는 trace로 확인)
- [ ] `/conventional-review "..."` 실행 시 haiku로 처리되는지
- [ ] `/coffee-time` 실행 시 백그라운드로 진행되는지
- [ ] `/skills-curate` 등 인터랙티브 명령이 정상 multi-turn 동작하는지
- [ ] 부작용 발견 시 해당 commit 만 revert (rollback-friendly)

---

## Failure Conditions (전체 plan)

다음 중 하나라도 발생 시 plan 진행 중단 + spec 재검토:

1. **Symlink 깨짐**: `stow .` 후 `~/.claude/templates/delegation.md` 등 symlink 미생성
2. **Frontmatter 파싱 오류**: 변경된 파일의 YAML frontmatter가 awk로 `---`...`---` 매칭 안 됨 (문법 오류)
3. **인터랙티브 파일에 sub-agent 호출 보일러플레이트 잘못 들어감**: `model:` 제거 task에서 변형 A/B/C boilerplate 잘못 삽입
4. **Reference 누락**: 변형 A/B/C 적용 파일이 `templates/delegation.md` reference 없이 `## 실행 모델` 섹션만 가짐
5. **Plugin 영역 침범**: 변경 사항이 `~/.claude/plugins/` 하위 파일을 건드림
6. **commit 누락**: Task N의 `git status`가 task 종료 시점에 staged/unstaged 파일을 남김
