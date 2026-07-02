# cj — claude project jump — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 설정된 claude 작업 프로젝트 목록에서 fzf로 하나를 골라, 이미 tmux pane에 열려 있으면 그 pane으로 점프하고 없으면 현재 pane에서 `cd`하는 zsh 함수 `cj`를 만든다.

**Architecture:** `cw`(cc-attention-router)가 이미 가진 "찾은 pane으로 점프" 로직(select-window/pane + aerospace 크로스-창 focus)을 공유 헬퍼 `_cc_goto`로 추출해 `cw`·`cj`가 공유한다. `cj`는 탐색 축만 다르다(상태 vs 프로젝트). 위험한 매칭/정규화 로직은 순수 함수 `_cj_match`로 격리해 단위 테스트한다.

**Tech Stack:** zsh (assoc array, `:A`/`:t` modifier, param expansion), tmux (list-panes, pane 옵션), aerospace, fzf, awk. 외부 프로세스 최소화(`:A`로 정규화).

## Global Constraints

- 전부 `dotfiles` repo. 신규 `.zsh.after/*.zsh`는 `.zshrc`에 명시 `source` 추가 필요(glob 아님).
- 모든 커밋은 `git commit --no-verify` (pre-commit stash 버그로 unstaged 유실 방지).
- `cw`의 기존 동작과 `test-cw.zsh`는 **변경 없이 계속 통과**해야 한다(회귀 게이트).
- 경로 매칭은 **양쪽 `${path:A}` 정규화 후 exact 일치**. subdir는 미개방 취급.
- 미개방 프로젝트 선택 시 **`cd`만** — claude 자동 실행·새 window 생성 금지.
- config는 `~/.zsh.after/cc-projects.list` (`.list` 확장자 → 소싱 안 됨).
- 테스트 러너: `zsh <file>`, 성공 시 `ALL PASS` 출력 + exit 0 (기존 `test-cw.zsh` 패턴).

---

## File Structure

| 파일 | 역할 | 변경 |
|------|------|------|
| `.zsh.after/cw.zsh` | `_cc_goto`(공유 이동 헬퍼) 정의, `cw`는 호출만 | Modify |
| `.zsh.after/cj.zsh` | `_cj_match`(순수 매칭) + `_cj_rows`(순수 표시) + `cj`(오케스트레이션) | Create |
| `.zsh.after/cc-projects.list` | 프로젝트 경로 목록(config) | Create |
| `.zsh.after/tests/test-cj.zsh` | `_cj_match`·`_cj_rows` 단위 테스트 | Create |
| `.zshrc` | `source ~/.zsh.after/cj.zsh` 1줄 | Modify |
| `.zsh.after/msbaek.cheats` | `cj` 항목(mshelp 발견성) | Modify |

---

## Task 1: `_cc_goto` 추출 + `cw` 리팩터 (동작 불변)

`cw`의 이동 꼬리를 `_cc_goto`로 추출한다. `cw`·`cj`가 공유할 유일한 이동 규약이 된다. 회귀 게이트는 기존 `test-cw.zsh`가 무변경으로 통과하는 것.

**Files:**
- Modify: `/Users/msbaek/dotfiles/.zsh.after/cw.zsh` (현재 33–65행의 `cw()`)
- Test: `/Users/msbaek/dotfiles/.zsh.after/tests/test-cw.zsh` (무변경, 회귀 실행만)

**Interfaces:**
- Produces: `_cc_goto <target>` — `target`=`session:window.pane`. tmux 밖=`tmux attach`, 같은 세션=`select-window`/`select-pane`, 다른 세션=aerospace 창 focus(fallback `switch-client`). 빈 `target`이면 no-op. Task 4(`cj`)가 이 함수를 호출한다.
- Consumes: `_cw_wid_for_session`(cw.zsh 기존, 무변경).

- [ ] **Step 1: 리팩터 전 회귀 baseline 확인**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cw.zsh`
Expected: `ALL PASS` (exit 0). 리팩터 후 동일해야 함.

- [ ] **Step 2: `cw()`를 `_cc_goto` + 축약된 `cw`로 치환**

`.zsh.after/cw.zsh`에서 현재 `cw()` 함수(주석 `# cw: 조회 → fzf → 이동...`부터 파일 끝 `}`까지, 31–65행)를 아래로 **통째 치환**한다. `_cw_rows`·`_cw_wid_for_session`(1–29행)은 그대로 둔다.

```zsh
# _cc_goto <target>: target(session:window.pane)으로 이동.
# tmux 밖=attach, 같은 세션=tmux 전환, 다른 세션=aerospace 창 focus(fallback switch-client).
# cw·cj 공유 이동 프리미티브. 빈 target이면 no-op.
_cc_goto() {
  local target="$1"
  [ -n "$target" ] || return

  # tmux 밖에서 실행 → 그냥 attach
  if [ -z "$TMUX" ]; then tmux attach -t "$target"; return; fi

  local sess="${target%%:*}" win="${target%.*}"
  local cur; cur="$(tmux display -p '#{session_name}' 2>/dev/null)"

  # 대상 세션의 활성 window/pane 설정 (해당 ghostty 창이 대상을 보여주도록)
  tmux select-window -t "$win" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null

  # 같은 세션(=같은 ghostty 창) → tmux 전환으로 충분
  [ "$sess" = "$cur" ] && return

  # 다른 세션 → 그 세션을 보여주는 ghostty 창을 aerospace 로 포커스 (현재 창은 후면 유지)
  local wid
  wid=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null | _cw_wid_for_session "$sess")
  if [ -n "$wid" ]; then
    aerospace focus --window-id "$wid" 2>/dev/null
  else
    # 열린 창 없음(detached 세션 등) → 현재 창에서 전환 fallback
    tmux switch-client -t "$target" 2>/dev/null
  fi
}

# cw: 대기 중인 claude 세션 조회 → fzf → 이동. 자기 pane(지금 보고 있는 것)은 제외.
cw() {
  local sel target self="$TMUX_PANE"
  sel=$(tmux list-panes -a -F '#{@cc_state}|#{@cc_since}|#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}' 2>/dev/null \
        | awk -F'|' -v self="$self" '$5!=self' \
        | _cw_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 \
              --header='🔴 대기 / 🟢 작업 / ⚪ idle │ Enter=이동' --reverse) || return
  target="${sel##*$'\t'}"
  _cc_goto "$target"
}
```

- [ ] **Step 3: 회귀 테스트 통과 확인**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cw.zsh`
Expected: `ALL PASS` (exit 0) — Step 1과 동일.

- [ ] **Step 4: `_cc_goto`·`cw` 정의 sanity 확인**

Run: `zsh -c 'source /Users/msbaek/dotfiles/.zsh.after/cw.zsh; type _cc_goto >/dev/null && type cw >/dev/null && echo DEFINED'`
Expected: `DEFINED`

- [ ] **Step 5: Commit**

```bash
cd /Users/msbaek/dotfiles
git add .zsh.after/cw.zsh
git commit --no-verify -m "refactor(cw): 이동 로직을 _cc_goto 로 추출 (cj 와 공유 준비)"
```

---

## Task 2: `_cj_match` 순수 함수 (매칭·정규화·첫매치·미존재)

이 기능에서 조용히 무는 버그(symlink 오판→중복 열기)가 나는 지점. 순수 함수로 격리해 실제 임시 디렉토리+심링크로 테스트한다.

**Files:**
- Create: `/Users/msbaek/dotfiles/.zsh.after/cj.zsh`
- Create: `/Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`

**Interfaces:**
- Produces: `_cj_match <expanded_path...>` — `~`-확장된 절대경로들을 위치인자로, tmux 라인(`target|path`)을 stdin으로 받는다. stdout은 프로젝트당 한 줄 `state|target|path|name`, `state`∈{`open`,`closed`,`missing`}, `open`이면 `target`=`session:window.pane`(같은 경로 여러 pane이면 tmux 나열 첫 매치), 그 외 `target`은 빈 문자열, `path`=입력 경로 원본(cd 대상), `name`=basename. 매칭은 양쪽 `${path:A}` 정규화 후 exact. Task 3(`_cj_rows`)·Task 4(`cj`)가 소비한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`.zsh.after/tests/test-cj.zsh` 생성:

```zsh
#!/usr/bin/env zsh
source ~/.zsh.after/cj.zsh
fail=0

# 실제 디렉토리 + 심링크로 :A 정규화를 정직하게 검증
tmproot=$(mktemp -d)
mkdir -p "$tmproot/real/PRs" "$tmproot/real/bo"
ln -s "$tmproot/real" "$tmproot/link"   # link → real (symlink dir)

# --- _cj_match ---
# open (exact): tmux 경로와 프로젝트 경로 동일
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs")
[ "$out" = "open|work:1.0|$tmproot/real/PRs|PRs" ] || { echo "FAIL exact-open: [$out]"; fail=1; }

# open (symlink): 프로젝트는 link 경로, tmux 는 real 경로 → :A 로 동일 판정
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/link/PRs")
echo "$out" | grep -q '^open|work:1.0|' || { echo "FAIL symlink-open: [$out]"; fail=1; }

# open (trailing slash): 프로젝트 경로 끝에 / → :A 로 제거되어 매칭
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs/")
echo "$out" | grep -q '^open|work:1.0|' || { echo "FAIL slash-open: [$out]"; fail=1; }

# closed: tmux 에 해당 경로 없음
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/bo")
[ "$out" = "closed||$tmproot/real/bo|bo" ] || { echo "FAIL closed: [$out]"; fail=1; }

# first match: 같은 프로젝트에 pane 2개 → 첫 target
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" "work:2.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs")
[ "$out" = "open|work:1.0|$tmproot/real/PRs|PRs" ] || { echo "FAIL first-match: [$out]"; fail=1; }

# missing: 실존하지 않는 경로
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/ghost")
[ "$out" = "missing||$tmproot/real/ghost|ghost" ] || { echo "FAIL missing: [$out]"; fail=1; }

# 여러 프로젝트 한 번에 (순서 보존)
out=$(printf '%s\n' "work:1.0|$tmproot/real/PRs" | _cj_match "$tmproot/real/PRs" "$tmproot/real/bo")
[ "$(echo "$out" | wc -l | tr -d ' ')" = "2" ] || { echo "FAIL multi-count: [$out]"; fail=1; }

rm -rf "$tmproot"
[ $fail -eq 0 ] && echo "ALL PASS"
exit $fail
```

- [ ] **Step 2: 테스트 실패 확인 (함수 미정의)**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`
Expected: FAIL — `_cj_match: command not found` (cj.zsh가 아직 함수 없음) 또는 assertion 실패.

- [ ] **Step 3: `_cj_match` 구현**

`.zsh.after/cj.zsh` 생성(첫 함수):

```zsh
# cj — 설정된 claude 프로젝트로 이동. 열림→pane 점프, 닫힘→현재 pane 에서 cd.
# 이동 프리미티브 _cc_goto 는 cw.zsh 에 정의(런타임에 호출).

# _cj_match <expanded_path...>: 프로젝트 경로들(위치인자) + tmux 'target|path'(stdin)
#   → 프로젝트당 'state|target|path|name' (state∈open/closed/missing).
#   양쪽 ${:A} 정규화 후 exact 매칭. 같은 경로 여러 pane 이면 tmux 나열 첫 매치.
_cj_match() {
  local -A pane_by_norm
  local target path norm
  while IFS='|' read -r target path; do
    [ -n "$path" ] || continue
    norm="${path:A}"
    [ -n "${pane_by_norm[$norm]}" ] || pane_by_norm[$norm]="$target"
  done

  local p name tgt pnorm
  for p in "$@"; do
    name="${p:t}"
    if [[ ! -d "$p" ]]; then
      print -r -- "missing||$p|$name"
      continue
    fi
    pnorm="${p:A}"
    tgt="${pane_by_norm[$pnorm]}"
    if [ -n "$tgt" ]; then
      print -r -- "open|$tgt|$p|$name"
    else
      print -r -- "closed||$p|$name"
    fi
  done
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`
Expected: `ALL PASS` (exit 0)

- [ ] **Step 5: Commit**

```bash
cd /Users/msbaek/dotfiles
git add .zsh.after/cj.zsh .zsh.after/tests/test-cj.zsh
git commit --no-verify -m "feat(cj): _cj_match 순수 함수 (경로 정규화 후 open/closed/missing 판정)"
```

---

## Task 3: `_cj_rows` 표시 포맷 (기호·정렬·payload)

`_cj_match` 출력을 fzf 표시 라인으로 변환한다. open🟢 → closed⚪ → missing⚠ 순 정렬, 마지막 필드에 선택 후 쓸 payload(open=target, else=path)를 담는다.

**Files:**
- Modify: `/Users/msbaek/dotfiles/.zsh.after/cj.zsh`
- Modify: `/Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`

**Interfaces:**
- Consumes: `_cj_match` 출력 `state|target|path|name` (stdin).
- Produces: `_cj_rows` — stdout 각 줄 `sortkey<TAB>display<TAB>state<TAB>payload`. `sortkey`∈{0,1,2}로 정렬됨. `display`=`<sym> <name> [(loc)]`. `payload`=open이면 target, else path. Task 4(`cj`)가 fzf `--with-nth=2`로 display만 보여주고, 선택 라인의 3·4번째 필드(state·payload)를 파싱한다.

- [ ] **Step 1: 실패하는 테스트 추가**

`.zsh.after/tests/test-cj.zsh`의 `rm -rf "$tmproot"` 줄 **직전에** 아래 블록을 삽입한다:

```zsh
# --- _cj_rows ---
rows=$(printf '%s\n' \
  "closed||/p/bo|bo" \
  "missing||/p/ghost|ghost" \
  "open|work:1.0|/p/PRs|PRs" | _cj_rows)

# 정렬: 1번째 데이터행(=key 0)은 open(PRs)
echo "$rows" | head -1 | grep -q 'PRs' || { echo "FAIL rows-sort-open-first: [$rows]"; fail=1; }
# 기호
echo "$rows" | grep 'PRs'   | grep -q '🟢' || { echo "FAIL rows-open-sym"; fail=1; }
echo "$rows" | grep 'bo'    | grep -q '⚪' || { echo "FAIL rows-closed-sym"; fail=1; }
echo "$rows" | grep 'ghost' | grep -q '⚠' || { echo "FAIL rows-missing-sym"; fail=1; }
# open 행: state 필드(3)=open, payload 필드(4)=target
line=$(echo "$rows" | grep 'PRs')
[ "$(echo "$line" | cut -d$'\t' -f3)" = "open" ]     || { echo "FAIL rows-open-state: [$line]"; fail=1; }
[ "$(echo "$line" | cut -d$'\t' -f4)" = "work:1.0" ] || { echo "FAIL rows-open-payload: [$line]"; fail=1; }
# closed 행: payload(4)=path
line=$(echo "$rows" | grep 'bo')
[ "$(echo "$line" | cut -d$'\t' -f4)" = "/p/bo" ]    || { echo "FAIL rows-closed-payload: [$line]"; fail=1; }
# missing 은 마지막(key 2)
echo "$rows" | tail -1 | grep -q 'ghost' || { echo "FAIL rows-missing-last: [$rows]"; fail=1; }
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`
Expected: FAIL — `_cj_rows: command not found` 또는 assertion 실패.

- [ ] **Step 3: `_cj_rows` 구현**

`.zsh.after/cj.zsh`에서 `_cj_match` 함수 정의 **직후**에 추가:

```zsh
# _cj_rows: stdin 'state|target|path|name' → 'sortkey\tdisplay\tstate\tpayload'.
#   open🟢(0) → closed⚪(1) → missing⚠(2) 정렬. payload=open?target:path.
_cj_rows() {
  awk -F'|' '
    {
      state=$1; target=$2; path=$3; name=$4
      if (state=="open")        { key=0; sym="🟢"; loc="  ("target")" }
      else if (state=="closed") { key=1; sym="⚪"; loc="" }
      else                      { key=2; sym="⚠"; loc="  (missing)" }
      payload=(state=="open")?target:path
      printf "%d\t%s %-26s%s\t%s\t%s\n", key, sym, name, loc, state, payload
    }' | sort -s -n -k1,1
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`
Expected: `ALL PASS` (exit 0)

- [ ] **Step 5: Commit**

```bash
cd /Users/msbaek/dotfiles
git add .zsh.after/cj.zsh .zsh.after/tests/test-cj.zsh
git commit --no-verify -m "feat(cj): _cj_rows 표시 포맷 (기호·정렬·payload)"
```

---

## Task 4: `cj` 오케스트레이션 + config + 등록 (수동 검증)

`cj` 본체(목록 읽기 → tmux 수집 → `_cj_match` → fzf → `_cc_goto`/`cd`), config 파일, `.zshrc` source, cheats 항목을 함께 넣고 라이브로 검증한다. (fzf/tmux 인터랙션은 단위 테스트 대신 수동 검증.)

**Files:**
- Modify: `/Users/msbaek/dotfiles/.zsh.after/cj.zsh` (`cj` 함수 추가)
- Create: `/Users/msbaek/dotfiles/.zsh.after/cc-projects.list`
- Modify: `/Users/msbaek/dotfiles/.zshrc` (16행 `source ...cw.zsh` 다음에 삽입)
- Modify: `/Users/msbaek/dotfiles/.zsh.after/msbaek.cheats`

**Interfaces:**
- Consumes: `_cj_match`(Task 2), `_cj_rows`(Task 3), `_cc_goto`(Task 1).

- [ ] **Step 1: `cc-projects.list` 생성**

`.zsh.after/cc-projects.list`:

```
# cj (claude project jump) 대상 프로젝트 목록.
# 한 줄당 절대경로(또는 ~). '#' 이후·빈 줄 무시.
~/git/kt4u/PRs
~/git/kt4u/bo
~/git/kt4u/plan-docs
~/git/kt4u/isms-evidence
~/git/kt4u/datadog
~/qmk_firmware
~/git/ai-agent/revfactory/webtoon-harness
~/git/msbaek-claude-plugins
```

- [ ] **Step 2: `cj` 함수 추가**

`.zsh.after/cj.zsh` 끝(`_cj_rows` 다음)에 추가:

```zsh
# cj [query]: 프로젝트 fzf → 열림이면 그 pane 으로 점프, 닫힘이면 현재 pane 에서 cd.
cj() {
  local file="$HOME/.zsh.after/cc-projects.list"
  [[ -f "$file" ]] || { echo "[cj] not found: $file"; return 1; }

  # config → 주석/공백 정리 후 배열, 선두 ~ 확장
  local -a projects
  projects=( ${(f)"$(awk 'NF{sub(/#.*/,""); gsub(/^[ \t]+|[ \t]+$/,""); if($0!="")print}' "$file")"} )
  projects=( ${projects/#\~/$HOME} )
  (( ${#projects} )) || { echo "[cj] empty list: $file"; return 1; }

  # 열린 pane 경로 수집 (tmux 서버 없으면 빈 문자열 → 전부 closed)
  local tmux_data
  tmux_data="$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}' 2>/dev/null)"

  local sel
  sel=$(_cj_match "${projects[@]}" <<< "$tmux_data" \
        | _cj_rows \
        | fzf --ansi --delimiter=$'\t' --with-nth=2 --query="${1:-}" \
              --header='🟢 열림 / ⚪ 닫힘 / ⚠ 없음 │ Enter=이동 or cd' --reverse) || return
  [ -n "$sel" ] || return

  local state payload
  state=$(printf '%s' "$sel" | cut -d$'\t' -f3)
  payload=$(printf '%s' "$sel" | cut -d$'\t' -f4)
  [ -n "$payload" ] || return

  if [[ "$state" == "open" ]]; then
    _cc_goto "$payload"
  else
    cd "$payload"
  fi
}
```

- [ ] **Step 3: `.zshrc`에 source 추가**

`.zshrc` 16행(`source ~/.zsh.after/cw.zsh`) **다음 줄에** 삽입:

```zsh
source ~/.zsh.after/cj.zsh
```

먼저 `~/.zshrc`가 dotfiles로의 symlink인지 확인(맞으면 dotfiles 편집이 곧 반영):
Run: `ls -la ~/.zshrc`
Expected: `~/.zshrc -> dotfiles/.zshrc` (symlink). 아니라면 `/Users/msbaek/dotfiles/.zshrc`를 편집.

- [ ] **Step 4: cheats 항목 추가**

`.zsh.after/msbaek.cheats`의 `cw` 항목(66행 `f<TAB>cw<TAB>...`) **다음 줄에** 삽입(필드 구분=탭):

```
f	cj	설정된 claude 프로젝트로 이동 (열림→pane 점프, 닫힘→cd)	claude
```

- [ ] **Step 5: 단위 테스트 회귀 확인 (두 파일)**

Run: `zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cw.zsh && zsh /Users/msbaek/dotfiles/.zsh.after/tests/test-cj.zsh`
Expected: `ALL PASS` 두 번.

- [ ] **Step 6: 로드 + 함수 정의 확인**

새 셸에서 `.zshrc` 로드 후 네 함수가 모두 정의되는지 확인:

Run: `zsh -ic 'source ~/.zshrc; type cj _cj_match _cj_rows _cc_goto' 2>&1 | grep -c 'shell function'`
Expected: `4` (cj·_cj_match·_cj_rows·_cc_goto 모두 shell function). config 파싱·매칭의 실동작은 Step 7 인터랙티브에서 검증.

- [ ] **Step 7: 인터랙티브 수동 검증 (사용자와 함께)**

터미널에서 직접:
1. `cj` → fzf 목록 확인(열림/닫힘 표시). 열린 프로젝트 선택 → 그 pane/창으로 이동하는지.
2. `cj` → 닫힌 프로젝트(예: datadog) 선택 → **현재 pane이 그 디렉토리로 cd** 됐는지(`pwd`).
3. `cj bo` → 초기 쿼리 `bo`로 필터되는지.
4. `mshelp` → `cj` 항목 검색되는지.

Expected: 4개 모두 기대대로. (실패 시 해당 동작만 디버깅.)

- [ ] **Step 8: Commit**

```bash
cd /Users/msbaek/dotfiles
git add .zsh.after/cj.zsh .zsh.after/cc-projects.list .zsh.after/msbaek.cheats .zshrc
git commit --no-verify -m "feat(cj): 프로젝트 fzf 이동 명령 + config + mshelp 등록"
```

---

## Self-Review (작성자 체크)

**Spec coverage** (승인조건 ↔ 태스크):
1. 목록·열림/닫힘 표시 → Task 3(`_cj_rows`) + Task 4 Step 6·7. ✅
2. 열림→pane 이동 → Task 1(`_cc_goto`) + Task 4(`cj` open 분기), Step 7-1. ✅
3. 닫힘→cd → Task 4(`cj` else 분기), Step 7-2. ✅
4. symlink/slash 정규화 매칭 → Task 2(`_cj_match` + symlink/slash 테스트). ✅
5. 미존재→⚠ → Task 2(missing 판정) + Task 3(⚠ 기호). ✅
6. mshelp 발견 → Task 4 Step 4·7-4. ✅
- 제약 "cw 불변" → Task 1 Step 1·3 회귀 게이트 + Task 4 Step 5. ✅
- 제약 "신규 .zsh는 .zshrc source" → Task 4 Step 3. ✅

**Placeholder scan:** TBD/TODO/"적절히 처리" 없음. 모든 코드 스텝에 실제 코드 포함. ✅

**Type consistency:**
- `_cj_match` 출력 `state|target|path|name` ↔ `_cj_rows` awk 파싱(`$1..$4`) 일치. ✅
- `_cj_rows` 출력 `key\tdisplay\tstate\tpayload` ↔ `cj`의 `cut -f3`(state)·`-f4`(payload) 일치. ✅
- `_cc_goto <target>` 시그니처 ↔ `cw`·`cj` 호출부 일치. ✅
- `state` 값 집합 {open,closed,missing} 세 함수 전반 일치. ✅
