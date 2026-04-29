---
name: vis-backlink-trigger
description: |
  Use when invoked from /obsidian:add-tag or /obsidian:add-tag-and-move-file as the
  final step. Evaluates heuristic signals on the just-classified document A, recommends
  proceed/skip for backward Related Notes refresh, then dispatches async subagent.
  Honors .disabled marker. Per-file dirty check.
argument-hint: "<A_path>"
model: sonnet
---

# vis-backlink Backward Trigger

이 스킬은 `/obsidian:add-tag` 또는 `/obsidian:add-tag-and-move-file` 의 마지막 step 에서
호출됩니다. 인자로 전달된 `A_path` 를 기준으로 backward Related Notes 갱신을 결정합니다.

`$ARGUMENTS` = A 의 경로 (vault root 기준 상대 또는 절대 경로).

## Step 1: 사전 가드 0 — .disabled 마커 확인

```bash
[ -f ~/.claude/state/vis-backlink/.disabled ] && echo "DISABLED" || echo "OK"
```

결과가 `DISABLED` 이면:
- 인라인 고지 출력:
  `ℹ️ backward 비활성화 (재활성화: /vis-backlink-toggle on)`
- **즉시 종료** (아래 모든 단계 skip, vis /search 호출 금지)

결과가 `OK` 이면 Step 2 진행.

## Step 2: 사전 가드 1 — vis daemon health 확인

```bash
curl -s --max-time 5 http://localhost:8741/health
```

응답이 없거나 오류이면 (`ENV_VIS_DOWN`):
- 인라인 알림:
  `⚠️ vis daemon 응답 없음 — backward 생략 (visd start 후 재시도)`
- **즉시 종료**

응답 정상이면 Step 3 진행.

## Step 3: 사전 가드 2 — 동시성 체크 + state_dir 부트스트랩

state_dir 부트스트랩 (없으면 생성):
```bash
mkdir -p ~/.claude/state/vis-backlink/active
mkdir -p ~/.claude/state/vis-backlink/history
```

동시성 체크:
```bash
ls ~/.claude/state/vis-backlink/active/*.json 2>/dev/null
```

결과가 있으면 (`CONCURRENT_DISPATCH`):
- 2초 대기 후 재확인 (최대 5초 polling)
- 5초 경과 후에도 active 이면: `⏳ 선행 backward job 대기 중 (5초 max)` 1회 알림 후 계속 polling
- phase 가 `completed`, `partial_failure`, `user_skipped`, `crashed` 중 하나가 되면 polling 해제
- `phase=crashed` 감지 시: 해당 JSON 을 active/ 에서 history/ 로 이동 후 `🧹 crashed job 자동 정리: <job_id>` 알림

결과가 없으면 Step 4 로 진행.

## Step 4: vis /search — Top 5 조회

A 의 제목 결정:
- A 파일의 frontmatter `title` 필드가 있으면 그 값 사용
- 없으면 첫 번째 `# ` 헤딩 텍스트 사용
- 둘 다 없으면 파일 basename (확장자 제거) 사용

```bash
curl -s --get \
  --data-urlencode "query=<A_title>" \
  "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=5"
```

응답 JSON 의 `results` 배열을 Top 5 로 사용.
응답 실패 (연결 거부, 빈 응답, JSON 파싱 오류) 시 → Step 2 의 ENV_VIS_DOWN 처리와 동일하게 알림 + 종료.

## Step 5: 휴리스틱 평가 (NC2)

`exclude_patterns` = `["work-log/**", "ATTACHMENTS/**", "<A_path 자신>"]`

**Hard Veto 신호 평가** (1개라도 발화 → skip 추천):

**S4: 자동 제외율**
- Top 5 results 각 경로를 `exclude_patterns` 와 대조
- 매칭 수 / 5 ≥ 0.6 (3개 이상 제외 대상) → S4 veto 발화
- veto_reason: `"자동 제외율 XX% (Top 5 중 N건이 work-log/draft)"`

**S5: frontmatter draft**
- A 파일의 frontmatter 를 Read 도구로 확인
- `status: draft` 또는 `draft: true` 가 있으면 → S5 veto 발화
- veto_reason: `"frontmatter draft 상태"`
- ⚠️ git uncommitted 상태는 draft 로 간주하지 않음. frontmatter 만 확인.

**Soft 신호 수집** (근거 표시용, veto 권한 없음):
- **S1**: A 본문 글자 수 (frontmatter 제외). `<500자` → `짧음`, `≥500자` → `충분`
- **S2**: A 경로가 `work-log/`, `daily/`, `journal/` 포함 여부 → `시간성 경로` 또는 `일반 경로`
- **S3**: Top 5 results 의 평균 score (소수점 2자리)

**추천 결정:**
- S4 또는 S5 veto 발화 → recommendation = `skip`
- 둘 다 없음 → recommendation = `proceed`

**남은 targets:**
- Top 5 에서 `exclude_patterns` 매칭 제거 → 실제 backward 대상 목록 (0~5개)

## Step 6: 분기 처리

### recommendation = skip

다음 형식으로 출력:
```
⚠️ backward skip 추천 — <veto_reason>
   soft signals: 본문 <S1결과>, <S2결과>, Top 5 평균 score <S3>
   대상 후보: <targets 경로 목록> (총 N건)
   강제 진행하시겠습니까? [y/N]
```

사용자 응답 대기:
- `y` 또는 `Y` → Step 7 (per-file dirty + dispatch) 로 진행. `override_reason = "user_override_skip"`
- `N`, `n`, Enter → state 기록 후 종료:
  ```
  state = {phase: "user_skipped", source: A_path, ended_at: <ISO8601>}
  ```
  `history/<YYYYMMDD-HHMMSS-basename>.json` 으로 저장.
  `ℹ️ backward skip 확정 (사용자)` 출력 후 **즉시 종료**.

### recommendation = proceed

Step 7 로 진행.

## Step 7: Per-file Dirty Check + Job 초기화

`job_id = YYYYMMDD-HHMMSS-<A basename without extension>`
예: `20260426-153022-my-note`

state JSON 초기 기록 (tmp → rename atomic):
```bash
JOB_ID="<job_id>"
STATE_FILE=~/.claude/state/vis-backlink/active/${JOB_ID}.json
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" << STATEEOF
{
  "job_id": "${JOB_ID}",
  "source": "<A_path>",
  "started_at": "<ISO8601>",
  "updated_at": "<ISO8601>",
  "phase": "dispatched",
  "reason": "<normal|user_override_skip>",
  "subagent_name": "vis-backlink-<job_id 앞 8자리>",
  "progress": {"total": 0, "done": 0, "failed": 0},
  "targets": [],
  "log_path": "~/.claude/logs/vis-backlink-$(date +%Y%m%d).log"
}
STATEEOF
mv "$TMP_FILE" "$STATE_FILE"
```

**Per-file dirty 체크** (A 자신은 무조건 무시):
각 target X 에 대해:
```bash
cd <vault_root> && git status --porcelain "<X_path>"
```
- 결과 있음 → X 는 `skipped_dirty` (state 에 기록, backward 대상 제외)
- 결과 없음 → X 는 `queued` (dispatch 대상)

`queued` 목록이 비어있으면:
- `ℹ️ backward skip — 모든 대상 파일이 현재 편집 중 (dirty). 다음 분류 시 재시도됩니다.` 출력
- state `phase: "all_dirty_skip"` → history/ 이동 → 종료

dirty skip 이 있으면 proceed 알림에 `(N건 dirty skip)` 추가.

## Step 8: Background Subagent Dispatch + 즉시 해제

proceed 알림 출력:
```
🔗 backward dispatched — Top 5 평균 <S3>, 제외 후 <queued수>건 대상 (job=<job_id>)
   상태 조회: /vis-backlink-status
```
dirty skip 있으면: `(M건 dirty skip)` 추가.

Agent 도구로 subagent dispatch:
- `subagent_type: "general-purpose"`
- `name: "vis-backlink-<job_id 앞 8자리>"`
- `run_in_background: true`
- `prompt`: 아래 내용 포함
  - 처리할 targets (queued 만)
  - 각 X 에 대해 수행할 C2 서브루틴:
    1. `Read X_path` → 원본 전체 읽기
    2. C3 파서로 섹션 분해: `(before, related_lines, after)`. 일탈 줄 (멀티라인 desc, `![[...]]` 이미지 링크) 감지 시 → 해당 X skip, state `targets[X].status="skipped_parse"`
    3. vis `/search` (`query=<X_title>`, `top_k=5`, `rerank=true`) → X 의 최신 Top 5. exclude_patterns 적용.
    4. 각 링크 L: 기존 desc 보존 또는 LLM 생성 (실패 시 snippet fallback)
    5. new_lines 조립 + `MultiEdit(X_path, old=원본, new=assembled)` — (a) atomic write
    6. state atomic update: `targets[X].status="done"` (tmp → rename 으로 (a) 원자성 보장)
    7. 에러 카탈로그 대응 (c):
       - `DATA_PARSE_FAIL` → skip, 로그
       - `DATA_FILE_MISSING` → skip
       - `LLM_DESC_GEN_FAIL` → snippet fallback
       - `IO_WRITE_FAIL` → skip, notification
  - Config: `top_k=5, bootstrap_mode=minimal, exclude_patterns=["work-log/**","ATTACHMENTS/**","<A_path>"]`
  - state JSON path: `~/.claude/state/vis-backlink/active/<job_id>.json`
  - vault_root 경로

dispatch 완료 후 메인 Claude **즉시 해제** (4초 이내).

**history/ 정리:**
```bash
ls -t ~/.claude/state/vis-backlink/history/ | tail -n +31 | xargs -I{} rm ~/.claude/state/vis-backlink/history/{}
```
