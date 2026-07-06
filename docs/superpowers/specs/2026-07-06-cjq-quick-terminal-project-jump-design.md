# cjq — quick terminal 전용 project jump — 설계

- **날짜**: 2026-07-06
- **Status**: draft (사용자 리뷰 대기)
- **재사용 도구**: tmux (new-window·list-panes·select-window/pane), aerospace (크로스-창 focus), fzf, osascript(quick terminal dismiss), mshelp/cheats
- **대상 repo**: `dotfiles` 단일 (`.zsh.after/cj.zsh`, `.zsh.after/cc-projects.list`, `.zsh.after/msbaek.cheats`)
- **관련**: `cj`(`2026-07-02-cj-claude-project-jump-design.md`)의 목록·매칭 로직을 재사용. `cwq`(`claude-session-attention-router` 계열, `cw.zsh`)의 `_cwq_jump`/`_cwq_dismiss` 이동 프리미티브를 재사용.

---

## 1. 문제 정의

`cj`는 일반 tmux pane에서 실행하는 것을 전제로 한다 — 닫힌 프로젝트를 고르면 **현재 pane에서 `cd`** 한다. 그런데 ghostty quick terminal(전역 단축키로 뜨는 오버레이 셸)에서 `cj`를 실행하면 그 pane은 곧 사라지므로 `cd`가 아무 의미가 없다.

이미 `cwq`가 같은 문제(quick terminal에서 이동)를 "claude 세션 상태" 축으로 풀어놓았다: 선택 시 quick terminal을 닫고(`_cwq_dismiss`) 대상 세션의 ghostty 창을 aerospace로 focus(`_cwq_jump`). `cj`에는 이 축(quick terminal 전용 이동)이 없다.

추가로, `cj`가 닫힌 프로젝트를 열 때 "새 window를 어느 tmux 세션에 만들 것인가"라는 질문이 새로 생긴다 — 지금은 프로젝트마다 암묵적으로 `memo` 또는 `work` 세션에 정착해 있는데, 이 배치가 코드 어디에도 명시돼 있지 않다.

## 2. 목표 & 승인 조건 (Acceptance Criteria)

**목표**: quick terminal에서 `cjq`를 실행해 프로젝트를 고르면, 열려 있으면 그 pane으로, 닫혀 있으면 (memo/work 중 정해진 세션에) 새 window를 만들어 그 pane으로 이동한다 — 두 경우 모두 quick terminal은 닫히고, `cjq` 자체는 (재조회 가능한) 루프를 유지한다.

승인 조건(테스트 가능):

1. `cc-projects.list`에서 `@memo` 태그가 붙은 경로는 `session=memo`, 없으면 `session=work`로 파싱된다.
2. `cjq`에서 **이미 열린** 프로젝트를 선택하면 quick terminal이 닫히고 그 pane이 있는 ghostty 창이 aerospace로 focus된다.
3. `cjq`에서 **닫힌/없는** 프로젝트를 선택하면, 태그로 정해진 세션(`memo`/기본 `work`)에 새 window가 만들어지고, quick terminal이 닫히며 그 창이 focus된다.
4. 새 window 생성이 실패해도(예: 대상 경로 없음) quick terminal이 닫히지 않고 `cjq` 루프가 계속된다(조용한 부분 실패, 사용자가 다시 시도 가능).
5. `cjq`는 한 번의 이동 후 자동 종료하지 않고 다음 선택을 받을 수 있는 상태를 유지한다(`cwq`와 동일한 루프 UX). Esc/Ctrl-C로 취소·종료.
6. 기존 `cj`(일반 pane용)는 `@memo` 태그가 섞인 `cc-projects.list`를 읽어도 태그를 프로젝트명/경로로 오인하지 않는다(기존 열림/닫힘 판정 그대로 유지).
7. `mshelp`에서 `cjq`를 검색·발견할 수 있다.

## 3. 제약 (non-negotiable)

- **기존 `cj` 동작·테스트 불변**: `_cj_match`/`_cj_rows`/`test-cj.zsh`는 그대로 통과. 목록 파싱만 태그를 벗겨내는 공유 헬퍼로 교체.
- **`cwq` 동작·테스트 불변**: `_cwq_jump`/`_cwq_dismiss`/`test-cw.zsh`는 그대로 재사용, 수정 없음.
- **세션 배치는 고정 스냅샷**: 런타임에 tmux를 조회해 "지금 이 프로젝트가 어디 열려 있나"로 동적 판단하지 않는다(닫힌 프로젝트는 애초에 조회할 대상이 없어 판단 불가) — `cc-projects.list`에 `@memo` 인라인 태그로 고정.
- **YAGNI**: `cwq`의 preview/Ctrl-R 새로고침 같은 v2 기능은 가져오지 않는다. quick terminal 닫힘 + 이동 + 루프만.

## 4. 실패 조건 (Failure Conditions)

- `_cj_load`가 `@memo` 태그를 벗기지 못해 기존 `cj`의 프로젝트명 표시나 열림/닫힘 판정이 깨진다.
- `cjq`가 새 window를 만들 때 대상 세션을 잘못 판단해(태그 파싱 버그) 엉뚱한 세션에 window가 쌓인다.
- 새 window 생성 실패 시 `_cwq_jump`가 빈 target으로 quick terminal을 닫아버려 사용자가 아무 데도 못 가고 quick terminal만 잃는다(조용한 나쁜 실패).
- `cjq` 루프가 tmux 상태를 매 반복 다시 읽지 않아, 방금 새로 연 프로젝트를 다시 선택했을 때 "닫힘"으로 오판해 같은 세션에 window를 중복 생성한다.
- `kt4u/teams`처럼 현재 두 세션에 걸쳐 있는 프로젝트의 태그 결정이 코드에 반영되지 않아 재현 불가능한 배치가 된다.

## 5. 설계 개요

`cj`와 **목록·매칭 로직은 그대로 공유**하고, "선택 이후 이동 방식"만 quick terminal 전용으로 분기한다 — `cw`→`cwq` 관계와 동일한 패턴.

```
cc-projects.list(@memo 태그) ──_cj_load(신규, 순수)──→ path\tsession 쌍
                                      │
tmux list-panes ──────────────────────┤
                                      ▼
                              _cj_match / _cj_rows (기존, 무변경)
                                      │
                                    fzf 선택
                                      │
                        ┌─────────────┴─────────────┐
                       열림                        닫힘/없음
                  _cwq_jump <target>        _cjq_new_and_jump <path> <session>(신규)
                  (기존 cwq 프리미티브)         = tmux new-window → _cwq_jump <새target>
```

`cjq()`는 이 전체를 `while true`로 감싸 `cwq`처럼 선택→이동 후에도 재조회 상태를 유지한다.

## 6. 상세 설계

### 6.1 UX
- `cjq` (quick terminal 안에서 실행) → 프로젝트 목록 fzf(열림🟢/닫힘⚪/없음⚠) → Enter로 이동, quick terminal 닫힘.
- 이동 후 `cjq` 루프는 계속 살아있음 — quick terminal을 다시 열면 곧바로 다음 fzf 프롬프트가 보인다(`cwq`와 동일 체감).
- Esc/Ctrl-C → 루프 종료(취소), quick terminal은 열린 채로 남는다(닫지 않음 — 아무 이동도 안 했으므로).

### 6.2 세션 태그 파싱 — `_cj_load <file>`
- `cc-projects.list`를 읽어 한 줄당 `path\tsession` 출력(순수 함수, stdin 없이 파일 인자).
- 파싱 규칙: `#` 이후 주석 제거 → 앞뒤 공백 trim → 빈 줄 skip → 줄 끝이 `@memo`면 `session=memo`이고 그 태그를 잘라냄, 아니면 `session=work`.
- `~` 확장은 하지 않는다(기존 `cj()`가 이미 `projects=( ${projects/#\~/$HOME} )`로 처리하던 자리를 그대로 유지 — 책임 분리).
- 기존 `cj()`의 인라인 awk 파싱을 이 함수 호출로 교체(태그 도입 후에도 태그 없는 기존 줄은 100% 동일하게 동작).

`cc-projects.list` 태그 추가(현재 memo 세션에 열려 있는 것 스냅샷):
```
~/git/kt4u/PRs
~/git/kt4u/bo
~/git/kt4u/plan-docs
~/git/kt4u/isms-evidence
~/git/kt4u/datadog
~/qmk_firmware @memo
~/git/ai-agent/revfactory/webtoon-harness
~/git/msbaek-claude-plugins
~/dotfiles @memo
~/claude-config @memo
~/git/kt4u/teams @memo
~/git/presentation-designer
~/DocumentsLocal/msbaek_vault @memo
~/git/projects/daily-dashboard
~/git/vault-intelligence @memo
~/temp @memo
```
(`kt4u/teams`는 현재 memo·work 양쪽에 열려 있음 — 사용자 결정으로 `memo`를 기본값으로 고정.)

### 6.3 동작 분기 — `cjq()` / `_cjq_new_and_jump`
- **열림**: `_cj_rows`가 이미 내려주는 target(`session:window.pane`)으로 곧장 `_cwq_jump <target>`.
- **닫힘/없음**: `session_of[$payload]`(태그 파싱 결과, 없으면 `work`)로 `_cjq_new_and_jump "$payload" "$session"` 호출.
  - `_cjq_new_and_jump`: `tmux new-window -t <session> -c <path> -P -F '#{session_name}:#{window_index}.#{pane_index}'`로 새 window를 만들고 그 결과 target을 바로 `_cwq_jump`에 넘긴다.
  - `new-window`가 실패하면(예: 경로 없음) target이 빈 문자열 → `_cwq_jump`는 이미 "빈 target=no-op"으로 짜여 있어 quick terminal을 닫지 않고 조용히 아무 일도 안 한다(승인 조건 4).
- 매 루프 반복 시작 시 `tmux list-panes`를 다시 읽어 `_cj_match` 입력으로 사용 — 방금 새로 연 프로젝트가 다음 조회에서는 "열림"으로 잡히도록 보장(실패조건 4번째 항목 대응).

### 6.4 코드 구조
- 전부 `cj.zsh`에 추가(기존 관례대로 `_cwq_jump`는 `cw.zsh`에서 런타임 참조, cross-file source 순서 이슈 없음 — `cj()`가 이미 `_cc_goto`를 같은 방식으로 참조 중).
- 신규: `_cj_load`, `_cjq_new_and_jump`, `cjq`.
- 변경: `cj()` 내부 목록 로딩부만 `_cj_load` 호출로 교체(그 외 로직 무변경).
- 무변경: `_cj_match`, `_cj_rows`, `cw.zsh` 전체.

### 6.5 순수 함수 & 테스트
- `_cj_load`: 임시 파일로 태그 있음/없음/주석/빈줄/trailing whitespace 케이스 검증.
- `_cjq_new_and_jump`: 기존 `_cwqjump_calls` 패턴처럼 `tmux`/`_cwq_jump`를 stub으로 가로채 (a) `new-window -t <session> -c <path>` 호출 인자 검증 (b) `_cwq_jump`가 `new-window`가 반환한 target으로 호출되는지 검증 (c) `new-window` 실패(빈 출력) 시 `_cwq_jump`가 빈 target으로 호출되어도 부작용 없음(기존 `_cwq_jump`의 빈 target 가드로 이미 보장 — 별도 재검증만).
- `test-cj.zsh`(기존)·`test-cw.zsh`(기존)는 무변경으로 계속 통과(회귀 게이트).

### 6.6 엣지 케이스
- `$TMUX` 안/밖 구분 없음 — `_cwq_jump`는 애초에 `$TMUX` 검사를 안 함(quick terminal은 tmux 클라이언트가 아닌 순수 셸이라는 기존 전제 유지).
- fzf 취소(Esc) → 루프 `break`, quick terminal 안 닫힘.
- 목록 파일 부재 → 명확한 에러 메시지 후 return(기존 `cj`와 동일 패턴).
- 없는 프로젝트(⚠) 선택 → "닫힘"과 동일 경로로 처리(기존 `cj`도 closed/missing을 구분 안 하고 동일 취급 — 일관성 유지). `new-window -c <존재안하는경로>`가 실패하면 4번 승인 조건대로 조용히 무시됨.

## 7. 산출물 (파일 매핑)

| 산출물 | repo/경로 | 성격 |
|--------|-----------|------|
| `_cj_load` + `_cjq_new_and_jump` + `cjq` | `dotfiles`/`.zsh.after/cj.zsh` | 신규 |
| `cj()` 목록 로딩부 교체 | `dotfiles`/`.zsh.after/cj.zsh` | 리팩터(동작 불변) |
| `@memo` 태그 7건 | `dotfiles`/`.zsh.after/cc-projects.list` | 수정 |
| 테스트(`_cj_load`, `_cjq_new_and_jump`) | `dotfiles`/`.zsh.after/tests/test-cj.zsh` | 추가 |
| cheats 항목 | `dotfiles`/`.zsh.after/msbaek.cheats` | 1줄 추가(`f cjq … claude`) |

## 8. 결정 로그 & 폐기 대안

- **세션 배치 = `cc-projects.list` 인라인 `@memo` 태그** (대안: 별도 `cc-projects-memo.list` 파일 / 런타임 동적 판단). 파일을 늘리지 않고 한 곳에서 프로젝트-세션 관계를 볼 수 있음. 런타임 동적 판단은 닫힌 프로젝트에 대해 원천적으로 불가능해 폐기.
- **`kt4u/teams` = memo 기본값** (현재 memo·work 양쪽에 열려 있는 중복 상태, 사용자가 memo로 명시 확정).
- **닫힘/없음 처리 통합** (대안: `missing`을 별도로 막아 에러 메시지 표시). 기존 `cj()`도 이 둘을 구분하지 않으므로 일관성을 위해 통합 유지 — v2 후보로 명시적 에러 표시를 남겨둠.
- **`cwq`의 preview/Ctrl-R 미차용**: 이번 요청 범위는 "닫힘+dismiss+이동+루프"뿐 — 스코프 확대 방지(YAGNI).
- **새 window는 `tmux new-window -P -F`로 target을 직접 받아 `_cwq_jump` 재사용** (대안: 새 primitive를 처음부터 작성). `_cwq_jump`가 이미 select-window/pane+dismiss+focus를 전부 하므로 new-window 결과만 먹이면 충분 — 중복 로직 방지.

## 9. Out of scope / v2 후보

- `missing`(존재하지 않는 경로) 선택 시 명시적 에러 메시지.
- `cjq`용 fzf preview(대상 경로 최근 파일/git status 등).
- Ctrl-R로 `cc-projects.list` 재로딩.
- 세션 배치를 3개 이상으로 확장(현재는 memo/work 이분법).

## 10. 승인 조건 ↔ 테스트 매핑

| 승인 조건 | 검증 수단 |
|-----------|-----------|
| 1 (`@memo` 태그 파싱) | `_cj_load` 단위 테스트 |
| 2 (열림→이동+닫힘) | 수동(라이브 quick terminal) — `_cwq_jump` 자체는 `test-cw.zsh`로 이미 검증됨 |
| 3 (닫힘→새 window+이동) | `_cjq_new_and_jump` 단위 테스트(stub) + 수동 |
| 4 (실패 시 조용한 무해) | `_cjq_new_and_jump` 단위 테스트(빈 target 케이스) |
| 5 (루프 유지) | 수동(라이브 quick terminal, `cwq`와 동일 체감 확인) |
| 6 (`cj` 회귀 없음) | 기존 `test-cj.zsh` 그대로 통과 |
| 7 (mshelp 발견) | cheats grep |
