# cc-orchestra

enc-mask처럼 **여러 프로젝트에 걸쳐 작업**할 때, 각 프로젝트에 Claude Code 인스턴스를 띄워두고 한 곳에서 지시를 dispatch하는 tmux 기반 오케스트레이터입니다.

---

## 왜 필요한가?

ISMS 작업처럼 enc-mask → pacman → thomas → bo 여러 프로젝트를 동시에 수정해야 할 때:

- **기존 방법**: 터미널 탭마다 `cd ~/git/kt4u/pacman && claude` 직접 실행 → 컨텍스트 스위칭 피로
- **cc-orchestra**: 한 번 `ccup`으로 환경 구성 → `ccsend pacman "..."` 로 dispatch → 각 CC는 자기 프로젝트의 CLAUDE.md/.claude/ 설정으로 동작

각 pane은 **해당 프로젝트 디렉토리에서 시작**하기 때문에 CLAUDE.md, `.claude/` 하위 설정, memory가 모두 정상 로딩됩니다.

---

## 구조

```
~/.claude/skills/cc-orchestra/
├── SKILL.md              ← Claude에게 이 skill을 어떻게 사용할지 알려주는 진입점
├── README.md             ← 이 파일
├── functions.zsh         ← .zshrc에 source하면 쓸 수 있는 zsh 단축 함수 모음
├── templates/
│   └── auto-dispatch.md  ← 메인 프로젝트 CLAUDE.md에 추가할 dispatch 룰 템플릿
└── scripts/
    ├── lib.sh            ← 모든 script가 공유하는 헬퍼 함수 (직접 실행 ×)
    ├── up.sh             ← 환경 생성 (tmux session/window + claude spawn)
    ├── down.sh           ← 환경 종료 (session/window kill + registry 삭제)
    ├── add.sh            ← 실행 중인 환경에 pane 추가 (low-level: task 인자 필요)
    ├── remove.sh         ← 실행 중인 pane 제거 (low-level: task 인자 필요)
    ├── list.sh           ← 활성 task와 pane 목록 출력 (인자 없음)
    ├── send.sh           ← 특정 pane에 텍스트 dispatch (low-level: task 인자 필요)
    ├── active-task.sh    ← 현재 tmux session에 매칭되는 task 자동 탐지
    ├── cc-dispatch.sh    ← CC Bash tool 진입점: active-task + send.sh wrapper
    ├── cc-add.sh         ← CC Bash tool 진입점: active-task + add.sh wrapper
    └── cc-remove.sh      ← CC Bash tool 진입점: active-task + remove.sh wrapper

~/.cc-orchestra/          ← 런타임 registry (자동 생성됨)
└── <task>.env            ← pane ID 저장소 (up.sh가 만들고 down.sh가 지움)
```

---

## 설치

`~/.zshrc`에 다음 줄이 있으면 됩니다 (이미 추가되어 있음):

```bash
source ~/.claude/skills/cc-orchestra/functions.zsh
```

새 터미널을 열거나 `source ~/.zshrc`를 실행하면 `ccup`, `ccdown` 등의 함수를 사용할 수 있습니다.

---

## 기본 사용법

cc-orchestra는 **두 환경에서 사용**합니다:

- **A. Terminal (zsh)** — 사용자가 직접 환경 구성·관리·dispatch (zsh function 사용)
- **B. Claude Code 채팅창** — 메인 pane의 CC와 대화하며 자연어 발화로 다른 pane에 자동 dispatch

위치별 가능/불가 매트릭스는 [명령 실행 위치](#명령-실행-위치--어디서-ccupccsendactive-tasksh를-부르는가) 섹션 참조.

---

### A. Terminal (zsh)에서 사용

사용자가 외부 터미널(또는 tmux 안 별도 zsh window)에서 zsh function을 호출합니다. 환경 구성·관리는 거의 모두 이쪽 경로.

#### A1. 환경 구성 — `ccup`

```bash
ccup <task이름> <메인프로젝트> <메인경로> [서브프로젝트 서브경로 ...]
```

```bash
# ISMS-184 작업: enc-mask를 메인으로, pacman과 thomas를 서브로
ccup isms184 \
  enc-mask ~/git/kt4u/enc-mask \
  pacman   ~/git/kt4u/pacman \
  thomas   ~/git/kt4u/thomas
```

실행하면:
- tmux session `isms184` 생성
- 좌측 큰 pane: enc-mask (claude 자동 실행)
- 우측 위 pane: pacman (claude 자동 실행)
- 우측 아래 pane: thomas (claude 자동 실행)
- `CC_ORCHESTRA_TASK=isms184` 자동 export
- `tmux attach-session -t isms184` 안내 출력
- 각 pane 출력이 `/tmp/cc-isms184-<proj>.log`에 기록됨
- 메인 프로젝트(enc-mask)의 `CLAUDE.md`에 Auto-Dispatch 섹션이 없으면 안내 출력 ([Auto-Dispatch 룰](#auto-dispatch-룰--메인-프로젝트-claudemd에-추가) 섹션 참조)

```
┌─────────────────────┬──────────────────┐
│                     │    pacman        │
│    enc-mask         │    (claude)      │
│    (claude)         ├──────────────────┤
│                     │    thomas        │
│                     │    (claude)      │
└─────────────────────┴──────────────────┘
```

**흔한 실수**:
- 같은 task명으로 두 번 실행: `tmux session 'isms184' already exists` → `ccdown isms184` 후 재시도
- path 오타: `cc-orchestra ERROR: main path does not exist` → 절대 경로 확인

#### A2. tmux 진입 — `tmux attach`

```bash
tmux attach-session -t isms184
```

진입하면 메인 pane(enc-mask)에 포커스. 다른 pane은 `Ctrl-b o`로 순환. detach는 `Ctrl-b d` (밖에서 ccsend 등 호출하려면 detach 또는 별도 zsh window 사용).

#### A3. 작업 지시 — `ccsend`

```bash
ccsend <프로젝트명> <프롬프트>
```

```bash
ccsend pacman "ISMS-184 배송 ID 대량 SSN 암호화를 구현해줘"
ccsend thomas "SSN_ENC 필드에 dual-write 패턴 적용해줘"
```

`CC_ORCHESTRA_TASK` 환경변수를 기준으로 어느 session의 pane인지 자동으로 찾아 dispatch.

**다른 터미널에서 같은 task에 dispatch하려면** 환경변수 수동 설정:

```bash
export CC_ORCHESTRA_TASK=isms184
ccsend pacman "추가 작업 지시"
```

**흔한 실수**:
- `cc-orchestra: project 'pacman' not found` → 프로젝트명 오타 또는 ccadd로 등록 안 됨. `cclist`로 확인
- claude 부팅 직후 ccsend → 입력 씹힘. `ccup` 후 5초 정도 대기

#### A4. 목록 확인 — `cclist`

```bash
cclist
```

```
── task: isms184  [session]  created: 2026-05-10T14:30:00
   enc-mask: %39 ✓
   pacman:   %40 ✓
   thomas:   %41 ✓
```

- `✓` — pane 살아있음
- `✗ dead` — pane이 종료됨. 보통 사용자가 `Ctrl-d`로 claude를 끝낸 경우. `ccrm` 후 `ccadd`로 재구성

#### A5. pane 동적 추가/제거 — `ccadd` / `ccrm`

```bash
# 작업 중 bo 프로젝트 추가 (좌우 분할에 새 pane 끼움)
ccadd bo ~/git/kt4u/bo

# 완료된 프로젝트 제거 (pane kill + registry 삭제)
ccrm thomas
```

`ccadd` 직후 그 pane의 claude가 부팅하는 데 약 5초 걸립니다. 즉시 `ccsend bo "..."` 보내면 입력이 씹힐 수 있어요.

#### A6. 환경 종료 — `ccdown`

```bash
ccdown isms184
```

- tmux session `isms184` 종료 (모든 pane kill)
- `~/.cc-orchestra/isms184.env` 삭제
- `CC_ORCHESTRA_TASK` 환경변수 unset

**중요**: `ccdown` 전에 각 pane CC의 작업 상태(uncommitted 변경, 진행 중 prompt)를 확인하세요. 강제 kill이므로 미완료 작업은 손실됩니다.

---

### B. Claude Code 채팅창에서 사용

`tmux attach-session -t <task>` 진입 후 메인 pane의 CC와 자연어로 대화. CC가 다른 프로젝트 pane으로 자동 dispatch를 수행합니다. 채팅창에서 직접 명령을 칠 일은 거의 없습니다.

#### B1. 자연어 dispatch (가장 자주 쓰는 경로)

메인 pane의 CC에게 그냥 평소처럼 말하면 됩니다:

```
사용자: pacman에서 README 첫 줄 출력해줘
사용자: thomas와 bo 모두에 SSN_ENC dual-write 적용해줘
사용자: ISMS-184 구현 계획 문서 읽고 Task 1부터 시작해줘
```

메인 CC가 다음을 수행:
1. 발화에서 프로젝트 이름 인식
2. dispatch 메시지 작성
3. **사용자에게 확인 요청** (메시지 미리보기 + "진행할까요?")
4. 사용자 승인 후 `cc-dispatch.sh` Bash tool로 호출
5. 결과 보고 (또는 사용자에게 해당 pane 확인 안내)

확인 요청 예시:

```
다음을 pacman pane에 dispatch하려고 합니다. 진행할까요?

ISMS-184 작업: docs/superpowers/plans/2026-05-08-isms184-...md
Task 1부터 시작. 완료 기준은 plan의 'Verification' 섹션 참조.
```

응답:
- "ㅇ", "yes", "진행" → CC가 dispatch 실행
- "no", "취소" → CC가 이유 묻고 재논의
- "메시지에서 X 빼고 Y 추가" → CC가 반영 후 재확인

#### B2. CC 자체 판단 dispatch

사용자가 프로젝트를 명시하지 않아도 메인 CC가 다음 신호로 자동 판단:

| 신호 | 예 |
|---|---|
| 변경할 파일 경로가 다른 repo | `pacman/src/...` 수정 필요 → pacman으로 dispatch |
| 계획 문서가 task를 특정 프로젝트에 할당 | plan의 "Task 1: pacman" → pacman |
| 빌드/테스트 책임이 다른 프로젝트 | Spring Boot 부팅 검증 → 해당 프로젝트 |
| **enc-mask 자체 처리 범위** | `docs/`, `README.md`, plan 파일은 메인이 직접 |

이 경우도 dispatch 전에 **반드시 사용자에게 확인**합니다. 메인 CC가 자기 판단으로 임의로 dispatch하지 않습니다.

#### B3. "여기서" — dispatch skip 발화

다음 발화는 메인 CC가 자기가 처리하라는 신호입니다 (dispatch 안 함):

```
사용자: 여기서 README 첫 줄만 보여줘
사용자: 이 파일 수정해줘
사용자: 현재 프로젝트의 docs 폴더 정리해줘
```

#### B4. 자동 진행 (escape hatch)

매번 확인이 번거로운 다단계 작업에는 사용자가 미리 자동 진행을 지시:

```
사용자: ISMS-184 Task 1~3까지 pacman에 자동으로 진행시켜줘. 확인 없이.
```

이 경우만 메인 CC가 후속 dispatch를 자동화. 기본은 항상 확인.

#### B5. 진행 모니터링

dispatch한 후 sub pane CC의 진행은 두 가지로 확인:

1. **사용자가 tmux에서 직접** — `Ctrl-b o`로 해당 pane 전환해 보거나, 사용자가 다른 터미널에서 `tail -f /tmp/cc-<task>-<proj>.log`
2. **메인 CC가 대신** — "pacman 작업 어디까지 됐어?" 라고 물으면 메인 CC가 `tail -n 30 /tmp/cc-<task>-pacman.log` 실행 후 요약 보고

#### B6. (참고) CC가 내부에서 호출하는 명령

CC는 Bash tool로 다음 wrapper script를 사용합니다 (사용자가 외울 필요는 없음):

```bash
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh <proj> "<prompt>"
~/.claude/skills/cc-orchestra/scripts/cc-add.sh <proj> <path>
~/.claude/skills/cc-orchestra/scripts/cc-remove.sh <proj>
```

각 wrapper는 내부에서 `active-task.sh`로 현재 tmux session의 task를 자동 탐지 후 low-level script(`send.sh` 등)로 위임합니다.

---

### C. tmux 안 별도 zsh pane/window에서 사용

`tmux attach` 진입한 상태에서 zsh function을 쓰고 싶을 때 (예: `cclist` 확인, `tail -f` 로그 모니터). 메인 pane은 claude가 점유 중이므로 별도 zsh가 필요합니다.

```bash
# 진입 후 새 window 생성 (현재 세션 안에 zsh shell window 1 추가)
Ctrl-b c

# 새 window에서 평소처럼 zsh function 사용 가능
cclist
tail -f /tmp/cc-isms184-pacman.log
ccsend bo "..."

# 작업 window로 복귀
Ctrl-b 0    # window 0 (claude pane들)
Ctrl-b 1    # window 1 (zsh shell, 방금 만든 것)
```

이 위치는 `TMUX` 환경변수가 살아있어서 `active-task.sh`도 정상 작동합니다 — `~/.claude/skills/cc-orchestra/scripts/active-task.sh`를 직접 실행해 현재 task명 확인 가능.

---

## Session vs Window 모드

| | Session 모드 (기본) | Window 모드 (`--window`) |
|--|--|--|
| **언제** | 며칠~1주 걸리는 ISMS 작업 | 당일 완료 가능한 짧은 작업 |
| **격리** | tmux session 단위 (강한 격리) | 기존 session 안의 window |
| **전환** | `tmux attach -t <task>` | `prefix + w`로 window 선택 |
| **병렬** | 여러 session 동시 운영 가능 | 하나의 session 안에 정리 |

```bash
# window 모드 사용
ccup --window isms184 enc-mask ~/git/kt4u/enc-mask pacman ~/git/kt4u/pacman
```

### Scope 우선순위

```
CLI flag (--window/--session)  >  CC_ORCHESTRA_SCOPE 환경변수  >  기본값 (session)
```

```bash
# 이 세션에서는 항상 window 모드로 (환경변수 설정)
export CC_ORCHESTRA_SCOPE=window
ccup isms184 enc-mask ~/git/kt4u/enc-mask   # --window 없어도 window 모드

# 특정 실행에서 session으로 override
ccup --session isms184 enc-mask ~/git/kt4u/enc-mask
```

---

## 환경변수

| 변수 | 설명 | 설정 시점 |
|------|------|-----------|
| `CC_ORCHESTRA_TASK` | 현재 활성 task 이름 | `ccup` 성공 시 자동 설정 |
| `CC_ORCHESTRA_SCOPE` | 기본 scope (session/window) | 수동 설정 또는 ccup --window 시 자동 |

`ccsend`, `ccadd`, `ccrm`은 모두 `CC_ORCHESTRA_TASK`를 참조합니다. 다른 터미널에서 같은 task에 접근하려면:

```bash
export CC_ORCHESTRA_TASK=isms184
ccsend pacman "추가 작업 지시"
```

---

## 로그 확인

각 pane의 출력은 자동으로 파일에 기록됩니다:

```bash
# pacman pane 출력 실시간 확인
tail -f /tmp/cc-isms184-pacman.log

# enc-mask pane 출력
tail -f /tmp/cc-isms184-enc-mask.log
```

---

## 전체 워크플로우 (사용자 명령 vs CC 자동 명령)

dispatch 경로는 두 갈래입니다:
- **사용자 직접** — 외부 zsh shell에서 zsh function (`ccsend`, `ccadd` 등) 호출
- **메인 CC 자동** — tmux 안 메인 pane의 Claude Code가 자연어 발화/자체 판단으로 script를 직접 호출

### 사용자가 터미널에서 (환경 구성 + 진입)

```bash
ccup isms220 enc-mask ~/git/kt4u/enc-mask pacman ~/git/kt4u/pacman
tmux attach -t isms220
# 메인 pane CC에 자연어로: "pacman에 README 첫 줄 출력시켜줘"
```

### 사용자가 직접 ccsend (zsh shell)

CC가 아닌 사용자 본인이 외부 터미널에서 dispatch할 때:

```bash
ccsend pacman "README 첫 줄 출력해줘"
```

### 메인 CC가 자동으로 (Bash tool)

CC의 Bash tool은 interactive zsh function을 못 보므로 **wrapper script를 1줄로 호출**:

```bash
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh pacman "README 첫 줄 출력해줘"
```

wrapper 내부에서 `active-task.sh`로 현재 tmux session ↔ task를 자동 매핑한 뒤 `send.sh`로 위임. `active-task.sh`는 session 이름과 `~/.cc-orchestra/*.env`의 `CC_TMUX_TARGET` prefix를 매칭해 session/window 모드 모두 지원. 매칭 0개/2개 이상이면 비0 종료 → CC는 사용자에게 task명을 명시적으로 묻는다.

pane 추가/제거도 같은 1줄 패턴:

```bash
~/.claude/skills/cc-orchestra/scripts/cc-add.sh thomas ~/git/kt4u/thomas
sleep 5   # claude 부팅 대기
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh thomas "<프롬프트>"

~/.claude/skills/cc-orchestra/scripts/cc-remove.sh thomas
```

활성 task 목록은 `~/.claude/skills/cc-orchestra/scripts/list.sh` (인자 없음 — 모든 task 출력하므로 wrapper 불필요).

#### Dispatch 트리거 — 메인 CC가 언제 자동 dispatch하는가

| Trigger | 신호 |
|---|---|
| **A. 사용자 명시 발화** | "pacman에서 X 해줘" / "thomas와 bo 모두에 Y" |
| **B. CC 자체 판단** | (1) 변경 대상 파일 경로가 다른 repo (2) 계획 문서가 task를 특정 프로젝트에 할당 (3) 빌드/테스트 책임이 다른 프로젝트 (4) 메인 프로젝트 자체 처리 범위 외 |
| **Skip** | "여기서 / 이 파일 / 현재 프로젝트" 또는 메인 프로젝트 자체 파일(`docs/`, `README.md`, 등) 작업 |

#### Dispatch 전 사용자 확인 필수

Trigger A·B 모두 **dispatch 전 매번 사용자에게 확인**한다. CC가 보여주는 형식:

```
다음을 <proj> pane에 dispatch하려고 합니다. 진행할까요?

<메시지 본문 미리보기>
```

사용자가 "이번 작업은 자동 진행"처럼 명시한 경우에만 후속 dispatch 자동화. 기본은 항상 확인.

dispatch 메시지는 **자체 완결적**이어야 합니다 (sub pane CC와 컨텍스트 공유 안 됨):
- 작업 컨텍스트 (계획 문서 경로, 티켓 번호)
- 시작 지점 (Task N부터, 또는 어느 파일부터)
- 완료/검증 기준

---

## Auto-Dispatch 룰 — 메인 프로젝트 CLAUDE.md에 추가

메인 CC가 dispatch 트리거와 확인 절차를 인지하려면 메인 프로젝트의 `CLAUDE.md`에 **Auto-Dispatch 섹션**이 있어야 합니다. `ccup`이 부재를 감지하면 안내를 출력합니다:

```
ℹ️  enc-mask/CLAUDE.md 에 Auto-Dispatch 섹션이 없습니다.
    메인 pane CC 가 자동 dispatch 룰을 인지하려면 다음 템플릿을 참조해 추가하세요:
    ~/.claude/skills/cc-orchestra/templates/auto-dispatch.md
    현재 task 의 sibling: pacman, thomas
```

### 추가 절차

```bash
# 1. 템플릿 확인
cat ~/.claude/skills/cc-orchestra/templates/auto-dispatch.md

# 2. 메인 프로젝트 CLAUDE.md 끝에 append (예: enc-mask)
cat ~/.claude/skills/cc-orchestra/templates/auto-dispatch.md >> ~/git/kt4u/enc-mask/CLAUDE.md

# 3. 편집 — sibling 프로젝트 placeholder를 실제 이름으로 교체
$EDITOR ~/git/kt4u/enc-mask/CLAUDE.md

# 4. 메인 pane CC에 반영하려면 해당 pane에서 /clear 또는 재시작
```

`ccup`은 git tracked 파일을 자동 수정하지 않습니다 — 안내만 하고 사용자가 검토 후 수동 추가.

---

## 명령 실행 위치 — 어디서 ccup·ccsend·active-task.sh를 부르는가

tmux 안의 claude pane에서는 zsh function을 못 부릅니다 (claude가 점유 중). 명령 실행 위치는 3종류:

| 위치 | 쓸 수 있는 것 |
|---|---|
| **A. tmux 밖 (외부 터미널)** | zsh function 모두 (ccup, ccsend, ...), 모든 script |
| **B. tmux 안 — claude pane** | 자연어로 메인 CC에게 지시 (B는 사용자 발화 위치, dispatch 트리거 발화) |
| **C. tmux 안 — 별도 zsh pane/window** | zsh function, script, **`active-task.sh`도 동작** ($TMUX 살아있음) |

**권장 setup**:
- 터미널 창 #1에서 `tmux attach -t <task>` (claude pane 관찰 + 자연어 발화)
- 터미널 창 #2 일반 zsh shell (`cclist` / `ccsend` / `tail -f /tmp/...`)
- 또는 한 터미널만 쓰면 attach 후 `Ctrl-b c`로 명령 전용 window 추가 → 그 window가 [C]

`active-task.sh`는 [C] 위치에서만 정상 동작 (tmux 환경변수 필요). [A]에서 실행하면 `not inside tmux`로 exit 1 — 의도된 fail-fast.

---

## 통합 시나리오 — ISMS-184 작업

```bash
# [A] 1. 환경 구성
ccup isms184 \
  enc-mask ~/git/kt4u/enc-mask \
  pacman   ~/git/kt4u/pacman

# (필요 시) ccup 안내에 따라 메인 프로젝트 CLAUDE.md에 Auto-Dispatch 섹션 추가

# [A] 2. tmux 진입
tmux attach-session -t isms184

# [B] 3. 메인 pane CC에 자연어
#       "ISMS-184 진행해줘"
#       → CC가 plan 문서 읽고 → "pacman pane에 dispatch할게요" 확인 요청
#       → 사용자 승인 → CC가 cc-dispatch.sh 호출 → pacman pane에 prompt 전달

# [C] 4. 진행 확인 (Ctrl-b c로 새 window)
cclist
tail -f /tmp/cc-isms184-pacman.log

# [B] 5. 추가 프로젝트 필요 시 자연어
#       "thomas 추가하고 SSN_ENC dual-write 적용시켜줘"
#       → CC가 cc-add.sh + cc-dispatch.sh 자동 호출 (확인 받고)

# [A] 6. 완료 후 정리
ccdown isms184
```

---

## 검증 가이드 (ccup 직후)

새 환경 구성 후 자동 dispatch가 살았는지 확인:

```bash
# [C] 활성 task 매핑 검사
~/.claude/skills/cc-orchestra/scripts/active-task.sh
# → "<task명>" 출력 (exit 0)

# [C] wrapper로 dispatch 동작 (CC가 쓸 경로)
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh <proj> "echo TEST"
tail -n 5 /tmp/cc-<task>-<proj>.log
# → "TEST" 또는 받은 입력 확인

# [B] 메인 CC end-to-end (자연어)
#     "<proj>에서 'pwd' 실행시켜줘"
#     → CC가 cc-dispatch.sh 호출, 확인 후 dispatch
```

---

## 직접 스크립트 사용

zsh 함수 없이 스크립트를 직접 실행할 수도 있습니다:

```bash
# 환경 구성
~/.claude/skills/cc-orchestra/scripts/up.sh isms184 \
  enc-mask ~/git/kt4u/enc-mask \
  pacman ~/git/kt4u/pacman

# dispatch (task 이름을 직접 지정)
~/.claude/skills/cc-orchestra/scripts/send.sh isms184 pacman "작업 지시"

# 목록
~/.claude/skills/cc-orchestra/scripts/list.sh

# 종료
~/.claude/skills/cc-orchestra/scripts/down.sh isms184
```

---

## 내부 동작 원리

1. **pane ID 기반 dispatch**: tmux의 pane ID(`%42` 형식)는 위치가 바뀌어도 불변. `up.sh`가 생성 즉시 캡처해서 `~/.cc-orchestra/<task>.env`에 저장.

2. **자연스러운 CC 설정 로딩**: 각 pane을 해당 프로젝트 경로(`-c <path>`)에서 시작하므로, `claude`가 실행될 때 그 프로젝트의 CLAUDE.md와 `.claude/` 설정이 자동 로딩.

3. **Registry 구조**: `~/.cc-orchestra/isms184.env` 예시:
   ```
   CC_SCOPE=session
   CC_TMUX_TARGET=isms184
   CC_CREATED=2026-05-10T14:30:00
   PANE_ENC_MASK=%39
   PATH_ENC_MASK=/Users/msbaek/git/kt4u/enc-mask
   PANE_PACMAN=%40
   PATH_PACMAN=/Users/msbaek/git/kt4u/pacman
   ```

4. **프로젝트명 → 키 변환**: `ktown4u-java` → `PANE_KTOWN4U_JAVA` (소문자+하이픈 → 대문자+언더스코어)

---

## 트러블슈팅

**"session already exists" 에러**
```bash
tmux kill-session -t isms184 2>/dev/null
rm -f ~/.cc-orchestra/isms184.env
ccup isms184 ...
```

**"task not found" 에러** (다른 터미널에서 ccsend 시)
```bash
export CC_ORCHESTRA_TASK=isms184
ccsend pacman "..."
```

**pane이 `✗ dead`로 표시될 때**
```bash
# 해당 프로젝트 pane 제거 후 재추가
ccrm pacman
ccadd pacman ~/git/kt4u/pacman
```

**로그 파일 위치 확인**
```bash
ls /tmp/cc-isms184-*.log
```
