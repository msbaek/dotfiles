# cj — claude project jump — 설계

- **날짜**: 2026-07-02
- **Status**: draft (사용자 리뷰 대기)
- **재사용 도구**: tmux (pane 옵션·list-panes·select-window/pane), aerospace (크로스-창 focus), fzf, zsh `:A` modifier, mshelp/cheats
- **대상 repo**: `dotfiles` 단일 (`.zsh.after/`, `.zshrc`, `docs/`)
- **관련**: `cw`(cc-attention-router, `2026-07-02-claude-session-attention-router-design.md`)의 이동 프리미티브를 공유

---

## 1. 문제 정의

자주 오가는 claude code 작업 project가 여러 개다(현재 8개). 어떤 것은 이미 tmux
pane에 열려 있고, 어떤 것은 아직 열지 않았다. 프로젝트로 가려면:

- 이미 열린 것 → 어느 세션·window·pane인지 기억해 손으로 찾아 이동.
- 안 열린 것 → 경로를 기억해 `cd`.

둘 다 **경로/위치를 머리로 기억**해야 하고, 이미 열린 프로젝트를 못 찾아 **현재
pane에서 중복으로 다시 여는** 낭비가 생긴다.

기존 `cw`는 *상태*(어느 세션이 내 응답 대기 중인가)로 이동한다. 프로젝트를
*이름/경로*로 곧장 가는 경로는 없다.

## 2. 목표 & 승인 조건 (Acceptance Criteria)

**목표**: 설정된 프로젝트 목록에서 하나를 골라, 이미 어느 pane에 열려 있으면 그
pane으로 점프하고, 없으면 현재 pane에서 그 디렉토리로 `cd`한다.

승인 조건(테스트 가능):

1. `cj` 실행 시 설정 파일의 모든 프로젝트가 fzf 목록에 뜨고, 각 항목은 **열림🟢/닫힘⚪** 상태가 표시된다. 열린 항목은 위치(`session:window`)를 함께 보여준다.
2. **이미 열린** 프로젝트를 선택하면 그 pane으로 **이동**한다 (같은 세션=tmux 전환, 다른 세션=aerospace 창 focus). = `cw`와 동일한 이동 규약.
3. **안 열린** 프로젝트를 선택하면 **현재 pane에서 `cd`**만 한다 (claude 자동 실행 없음, 셸 프롬프트 유지).
4. pane의 실제 경로와 설정 경로가 **symlink/trailing-slash로 달라도** 같은 프로젝트로 올바르게 매칭된다 (양쪽 `:A` 정규화).
5. 설정 파일에 실존하지 않는 경로가 있으면 목록에 **`⚠` 마커로 표시**된다 (조용히 사라지지 않음).
6. `mshelp`에서 `cj`를 검색·발견할 수 있다.

## 3. 제약 (non-negotiable)

- **미개방 시 cd만**: claude 자동 실행·새 window 생성 안 함 (사용자 결정: 가장 비파괴적).
- **`cw` 동작 불변**: 이동 로직을 공유 헬퍼로 추출하되 `cw`의 기존 동작·기존 테스트(`test-cw.zsh`)는 그대로 통과.
- **stow 규칙**: 전부 `dotfiles` repo. `.zsh.after` 신규 파일은 `.zshrc`에 명시 `source` 추가 필요(glob 아님).
- **경로 매칭은 정규화 후 비교**: `~` 확장만으로 불충분 — symlink 많은 환경.
- **YAGNI**: fzf 단일 목록 + 이동/cd. claude 실행·window 생성·prefix 매칭은 v2 후보.

## 4. 실패 조건 (Failure Conditions)

- 경로 정규화 누락 → 열린 프로젝트를 "닫힘"으로 오판 → 현재 pane에 **중복으로 다시 연다** (가장 조용하고 나쁜 실패).
- 매칭/조인 로직이 `cj` 본문에만 있어 **테스트가 표시 포맷만 덮고 정작 위험한 매칭은 안 덮는다**.
- `.zsh.after`에 `.zsh` 확장자로 config를 두어 셸이 실행하려다 에러.
- `cw` 이동 꼬리를 추출하다 `cw` 동작이나 `test-cw.zsh`를 깨뜨린다.
- 같은 프로젝트에 pane이 여러 개일 때 이동 대상이 비결정적이라 매번 다른 곳으로 튄다.

## 5. 설계 개요

`cw`와 **탐색 축만 다르다**(상태 vs 프로젝트). "찾은 대상 pane으로 점프"라는 하부
동작은 동일하므로, `cw`의 이동 꼬리(select-window/pane + aerospace 크로스-창
focus)를 **공유 헬퍼 `_cc_goto <target>`**로 추출해 `cw`·`cj`가 같은 규약을 쓴다.

```
cj → 설정목록 읽기 ─┐
                    ├─ _cj_match (순수) ─→ fzf ─→ 선택
tmux list-panes ────┘                              │
                                     ┌─────────────┴─────────────┐
                                  열림                          닫힘
                              _cc_goto <target>              cd <path>
```

## 6. 상세 설계

### 6.1 UX
- `cj` (인자 없음) → 프로젝트 목록 fzf 표시(열림/닫힘·위치 주석) → Enter.
- `cj <query>` → fzf `--query`로 전달(빠른 필터). 일관성 위해 결과가 유일해도 fzf는 노출.

### 6.2 동작 분기
- **열림**: 어떤 pane의 정규화된 `pane_current_path`가 정규화된 프로젝트 경로와 **정확히 일치** → `_cc_goto <target>`.
- **미개방**: `cd <path>`. `cj`가 셸 함수라 프롬프트에서 실행 → 현재 pane에 직접 적용.
- `$TMUX` 없음 → 열림 판정 스킵, 그냥 `cd`.

### 6.3 목록 소스
- `~/.zsh.after/cc-projects.list` (dotfiles stow, `.list`라 미소싱 → 안전).
- 한 줄당 절대경로, `#` 주석·빈 줄 무시, 선두 `~` 확장.
- 주신 8개로 seed:
  ```
  ~/git/kt4u/PRs
  ~/git/kt4u/bo
  ~/git/kt4u/plan-docs
  ~/git/kt4u/isms-evidence
  ~/git/kt4u/datadog
  ~/qmk_firmware
  ~/git/ai-agent/revfactory/webtoon-harness
  ~/git/msbaek-claude-plugins
  ```

### 6.4 매칭 규칙
- 비교 전 **양쪽 `:A` 정규화**(절대경로화 + symlink 해석). `${dir:A}`는 외부 프로세스 없이 zsh 내장으로 수행.
- 프로젝트 **루트 경로 정확 일치**만 "열림". subdir는 미개방 취급 — claude는 루트에서 뜨므로 예측 가능(§8 결정).
- 같은 프로젝트에 pane 여러 개 → tmux 나열 순서상 **첫 매치**로 이동(결정적).
- 실존하지 않는 경로 → 목록에 `⚠`로 표시, 선택 시 `cd`가 자연 에러.

### 6.5 코드 구조 & 공유 리팩터
- `cw.zsh`: `cw`의 이동 꼬리(현 46–64행)를 `_cc_goto <target>`로 추출. `cw`는 이를 호출하도록 축약. `_cw_wid_for_session`은 이름·동작 그대로 재사용(→ `test-cw.zsh` 무영향).
- 신규 `cj.zsh`: `_cj_match`(순수) + `_cj_rows`(순수, 표시 포맷) + `cj`(오케스트레이션: 목록·tmux 수집 → match → fzf → goto/cd).
- `.zshrc`(dotfiles)에 `source ~/.zsh.after/cj.zsh` 한 줄 추가.

### 6.6 순수 함수 & 테스트 (실패조건 #2 대응)
- `_cj_match`: **stdin = canned 프로젝트 목록 + canned `tmux list-panes` 출력**(인자 또는 두 스트림), **stdout = `state|target|path|name`**. 여기서 정규화·open/closed 판정·첫 매치·미존재 처리를 전부 수행. → 위험 로직이 순수 함수로 격리됨.
- `_cj_rows`: `state|target|path|name` → fzf 표시 라인(`display\tstate\ttargetOrPath`).
- `test-cj.zsh`(신규, `test-cw.zsh` 패턴): 검증 케이스
  - 열린 프로젝트 → `state=open` + 올바른 target.
  - 안 열린 프로젝트 → `state=closed`.
  - trailing-slash / symlink 경로 → 여전히 매칭(정규화).
  - 같은 프로젝트 pane 2개 → 첫 매치 target.
  - 미존재 경로 → `⚠` 마커.
- `test-cw.zsh`는 무변경으로 계속 통과(회귀 게이트).

### 6.7 엣지 케이스
- 자기 pane 선택 → cd/no-op 무해 (cw와 달리 self 제외 불필요).
- fzf 취소(ESC) → 아무 동작 없이 return.
- 목록 파일 부재 → 명확한 에러 메시지 후 return.

## 7. 산출물 (파일 매핑)

| 산출물 | repo/경로 | 성격 |
|--------|-----------|------|
| `_cc_goto` 추출 + `cw` 축약 | `dotfiles`/`.zsh.after/cw.zsh` | 리팩터(동작 불변) |
| `cj` + `_cj_match` + `_cj_rows` | `dotfiles`/`.zsh.after/cj.zsh` | 신규 |
| `source` 라인 | `dotfiles`/`.zshrc` | 1줄 추가 |
| 프로젝트 목록 | `dotfiles`/`.zsh.after/cc-projects.list` | 신규 config |
| 테스트 | `dotfiles`/`.zsh.after/tests/test-cj.zsh` | 신규 |
| cheats 항목 | `dotfiles`/`.zsh.after/msbaek.cheats` | 1줄 추가(`f cj … claude`) |

## 8. 결정 로그 & 폐기 대안

- **미개방 동작 = cd만** (선택지: cd만 / cd+claude / 새 window). → 가장 비파괴적, 사용자 명시 요청("현재 window/pane에서 이동")과 일치. cd+claude·새 window는 v2 후보.
- **목록 소스 = 별도 config 파일** (선택지: config 파일 / 함수 내 배열 / 자동발견). → 코드 수정 없이 프로젝트 추가, `.list`라 소싱 안전.
- **이름 = `cj`** (claude jump). `cw`와 짝을 이룸.
- **매칭 = exact 유지** (대안: 안전한 prefix 매칭). literal 요청엔 prefix가 더 부합하고 중복 열기를 더 막지만, 라이브 tmux 덤프상 claude가 루트에서 뜨므로 exact가 예측 가능하고 단순. **의도된 결정**으로 기록 — 필요 시 v2에서 경계 `/` 포함 prefix로 확장.
- **첫 매치 이동** (대안: claude 실행 pane 우선). claude 프로세스명(`2_1_198` 류)이 버전 취약해 v1은 결정적 첫 매치. prefer-claude는 v2 후보.
- **호스팅 Plan 표면 폐기**: `/visual-plan` 호스팅 인증은 외부 DB 기록 + UI 없는 플랜엔 이득 작음 → git 추적 마크다운 spec 채택.

## 9. Out of scope / v2 후보

- 미개방 시 claude 자동 실행 옵션(`cj -c`).
- prefix(subdir) 매칭.
- 같은 프로젝트 pane 다수 시 claude 실행 pane 우선 or 2차 fzf.
- 새 tmux window에서 열기 옵션.
- tmux 밖에서의 attach 처리 고도화.

## 10. 승인 조건 ↔ 테스트 매핑

| 승인 조건 | 검증 수단 |
|-----------|-----------|
| 1 (목록·상태 표시) | `_cj_rows` 단위 테스트 + 수동 `cj` |
| 2 (열림→이동) | 수동(라이브 tmux) — `_cc_goto`는 `cw` 경로로 이미 검증됨 |
| 3 (닫힘→cd) | 수동 |
| 4 (정규화 매칭) | `_cj_match` 단위 테스트(symlink/slash 케이스) |
| 5 (`⚠` 미존재) | `_cj_match`/`_cj_rows` 단위 테스트 |
| 6 (mshelp 발견) | cheats grep |
