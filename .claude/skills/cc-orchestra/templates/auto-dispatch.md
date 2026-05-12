## Auto-Dispatch (메인 pane CC 동작 규칙)

이 디렉토리에서 `cc-orchestra ccup`으로 띄워진 Claude Code 세션은 멀티-프로젝트 워크스페이스의 **메인 pane**. 다른 프로젝트(<sibling projects 나열: 예 proj-a / proj-b / proj-c>) 작업은 자기가 직접 하지 말고 그 프로젝트 pane으로 dispatch한다.

### Dispatch 명령 (Bash tool)

```bash
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh <proj> "<프롬프트>"
```

wrapper 내부에서 active-task 자동 탐지. 실패(tmux 밖, 매칭 0/2+개) 시 dispatch 보류 + 사용자에게 task 명시 요청.

### Trigger A — 사용자 명시 발화

| 발화 | 행동 |
|---|---|
| "<proj>에서/에 X 해줘" | 해당 proj로 1회 dispatch |
| "<proj-a>와 <proj-b> 모두에 Y" | 두 pane으로 순차 dispatch |
| "여기서 / 이 파일 / 현재 프로젝트" | 자기가 처리 (dispatch 안 함) |

### Trigger B — CC 자체 판단

사용자가 프로젝트를 명시하지 않아도 다음 신호가 있으면 dispatch:

1. **변경 대상 파일 경로**가 메인 프로젝트가 아닌 다른 repo 디렉토리.
   예: `<proj-a>/src/...` → 그 프로젝트로 dispatch.
2. **계획 문서**(예: `docs/superpowers/plans/*.md` 또는 본인 컨벤션의 plan 파일)가 task를 특정 프로젝트에 할당.
3. **빌드/테스트 책임**이 다른 프로젝트.
   예: 특정 서비스 부팅 검증 → 해당 프로젝트 pane.
4. **메인 프로젝트 자체 처리 범위**: 이 저장소의 자기 파일(`docs/`, `README.md`, `CLAUDE.md`, 워크스페이스 메타). 그 외는 dispatch 후보.

### Dispatch 전 절차 (사용자 확인 필수)

1. 어느 프로젝트인지 1차 판단 (위 신호).
2. **dispatch 메시지를 먼저 작성** — 자체 완결적으로:
   - 작업 컨텍스트 (관련 계획 문서 경로, 티켓 번호)
   - 시작 지점 (Task N부터, 또는 어느 파일부터)
   - 완료/검증 기준 (테스트 통과 등)
3. **사용자에게 항상 확인을 요청한다** — Trigger A(사용자 발화)든 Trigger B(자체 판단)든 모든 dispatch 전 매번 확인. 형식:

   ```
   다음을 <proj> pane에 dispatch하려고 합니다. 진행할까요?

   <메시지 본문 미리보기>
   ```

   사용자 응답 패턴:
   - "ㅇ", "yes", "진행" → dispatch 실행
   - "no", "아니" → 취소 + 이유 묻기
   - 메시지 수정 지시 → 반영 후 재확인
4. 승인된 후에만 `send.sh` 호출.
5. dispatch 후 결과 확인:
   - `tail -n 30 /tmp/cc-<task>-<proj>.log`
   - 또는 사용자에게 "<proj> pane 확인 부탁드립니다" 안내.

> 중간 단계가 많은 작업에서 매번 확인이 번거로우면 사용자가 "이번 작업은 자동으로 진행" 같이 명시한 경우에만 후속 dispatch 자동화. 기본은 항상 확인.

### Pane 추가/제거가 필요할 때

dispatch 대상 pane이 없으면 먼저 추가:

```bash
~/.claude/skills/cc-orchestra/scripts/cc-add.sh <proj> <path>
sleep 5   # claude 부팅 대기
~/.claude/skills/cc-orchestra/scripts/cc-dispatch.sh <proj> "<프롬프트>"
```

pane 제거: `~/.claude/skills/cc-orchestra/scripts/cc-remove.sh <proj>`
