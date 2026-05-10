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
├── SKILL.md          ← Claude에게 이 skill을 어떻게 사용할지 알려주는 진입점
├── README.md         ← 이 파일
├── functions.zsh     ← .zshrc에 source하면 쓸 수 있는 zsh 단축 함수 모음
└── scripts/
    ├── lib.sh        ← 모든 script가 공유하는 헬퍼 함수 (직접 실행 ×)
    ├── up.sh         ← 환경 생성 (tmux session/window + claude spawn)
    ├── down.sh       ← 환경 종료 (session/window kill + registry 삭제)
    ├── add.sh        ← 실행 중인 환경에 pane 추가
    ├── remove.sh     ← 실행 중인 pane 제거
    ├── list.sh       ← 활성 task와 pane 목록 출력
    └── send.sh       ← 특정 pane에 텍스트 dispatch

~/.cc-orchestra/      ← 런타임 registry (자동 생성됨)
└── <task>.env        ← pane ID 저장소 (up.sh가 만들고 down.sh가 지움)
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

### 1. 환경 구성 — `ccup`

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
- 좌측 큰 pane: enc-mask (claude 실행됨)
- 우측 위 pane: pacman (claude 실행됨)
- 우측 아래 pane: thomas (claude 실행됨)
- `CC_ORCHESTRA_TASK=isms184` 자동 설정
- `tmux attach-session -t isms184` 안내 출력
- 각 pane 출력이 `/tmp/cc-isms184-<proj>.log`에 기록됨

```
┌─────────────────────┬──────────────────┐
│                     │    pacman        │
│    enc-mask         │    (claude)      │
│    (claude)         ├──────────────────┤
│                     │    thomas        │
│                     │    (claude)      │
└─────────────────────┴──────────────────┘
```

### 2. 작업 지시 — `ccsend`

```bash
ccsend <프로젝트명> <프롬프트>
```

```bash
# pacman CC에게 작업 지시
ccsend pacman "ISMS-184 배송 ID 대량 SSN 암호화를 구현해줘"

# thomas CC에게 작업 지시
ccsend thomas "SSN_ENC 필드에 dual-write 패턴 적용해줘"
```

`CC_ORCHESTRA_TASK` 환경변수를 기준으로 어느 session의 pane인지 자동으로 찾아서 dispatch합니다.

### 3. 목록 확인 — `cclist`

```bash
cclist
```

```
── task: isms184  [session]  created: 2026-05-10T14:30:00
   enc-mask: %39 ✓
   pacman:   %40 ✓
   thomas:   %41 ✓
```

`✓`는 pane이 살아있음, `✗ dead`는 종료된 상태를 의미합니다.

### 4. pane 동적 추가/제거

```bash
# 작업 중 bo 프로젝트 추가
ccadd bo ~/git/kt4u/bo

# 완료된 프로젝트 제거
ccrm thomas
```

### 5. 환경 종료 — `ccdown`

```bash
ccdown isms184
```

- tmux session `isms184` 종료
- `~/.cc-orchestra/isms184.env` 삭제
- `CC_ORCHESTRA_TASK` 환경변수 unset

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

## 전체 워크플로우 예시

```bash
# 1. 작업 환경 구성
ccup isms184 \
  enc-mask ~/git/kt4u/enc-mask \
  pacman   ~/git/kt4u/pacman

# 2. tmux session 진입 (별도 터미널 또는 현재 창에서)
tmux attach-session -t isms184

# 3. 각 프로젝트에 작업 dispatch (zsh에서)
ccsend pacman "ISMS-184 구현 계획 문서 읽고 Task 1부터 시작해줘"
ccsend enc-mask "pacman 작업 진행 상황 모니터링하고 필요시 가이드 줘"

# 4. 진행 확인
cclist

# 5. 작업 중 추가 프로젝트 필요 시
ccadd thomas ~/git/kt4u/thomas
ccsend thomas "thomas 쪽 SSN_ENC dual-write 적용해줘"

# 6. 완료 후 정리
ccdown isms184
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
