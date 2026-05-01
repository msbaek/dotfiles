# K-QMD Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 `qmd` (Homebrew, v1.1.5)를 [K-QMD](https://github.com/jylkim/kqmd) (npm drop-in replacement)로 교체하고, Qwen3 임베딩 기준 인덱스를 재생성하며, 미래 세션 인지를 위한 메모리 1건을 추가한다.

**Architecture:** kqmd는 `qmd` 명령어를 그대로 노출하는 drop-in이므로 skill·script·문서 변경 없이 바이너리/인덱스만 교체한다. 미래 인지를 위한 reference 메모리를 새로 작성한다.

**Tech Stack:** npm (kqmd 패키지), Homebrew (qmd 제거 또는 unlink), 사용자 메모리 시스템 (`~/.claude/projects/-Users-msbaek-dotfiles/memory/`)

**Spec:** `docs/superpowers/specs/2026-05-02-kqmd-migration-design.md`

---

## File Structure

### Files to create
- `~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md` — K-QMD 백엔드 사실 메모 (type: reference)

### Files to modify
- `~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md` — Reference 섹션에 인덱스 1줄 추가

### Files explicitly NOT touched (per spec)
- `bin/qmd-search`, `.claude/skills/find-session/SKILL.md`, `.claude/skills/agf/SKILL.md`, `.claude/skills/recall/SKILL.md`, `.claude/settings.local.json`, `docs/superpowers/specs/2026-03-30-qmd-auto-index-design.md`

### System changes (no source files)
- Homebrew `qmd` 패키지 unlink/uninstall
- npm 글로벌 `kqmd` 패키지 install
- qmd 인덱스 재생성

---

## Task 1: 사전 점검 (Baseline 기록)

목표: 변경 전 상태를 기록해 사후 비교와 롤백 기준점을 만든다.

**Files:** 없음 (read-only 확인)

- [ ] **Step 1: 현재 qmd 설치 위치/버전 확인**

```bash
which qmd
qmd --version
brew list qmd 2>&1 | head -5
```

Expected:
- `which qmd` → `/opt/homebrew/bin/qmd`
- `qmd --version` → `qmd 1.1.5 (b9763ee528)`
- `brew list qmd` → 패키지 파일 목록

- [ ] **Step 2: 인덱스 상태 확인**

```bash
qmd collection list 2>&1
```

Expected: 컬렉션 목록과 각 컬렉션의 `Files: <N>` 출력. N 값을 기록 (사후 비교용).

- [ ] **Step 3: Baseline 검색 결과 기록 (한국어 자연어 쿼리)**

```bash
qmd-search "보안 취약점" 2>/dev/null | head -20 > /tmp/qmd-baseline-1.txt
qmd-search "테스트 커버리지" 2>/dev/null | head -20 > /tmp/qmd-baseline-2.txt
qmd-search "Jenkins 파이프라인" 2>/dev/null | head -20 > /tmp/qmd-baseline-3.txt
wc -l /tmp/qmd-baseline-*.txt
```

Expected: 각 파일에 검색 결과가 기록됨. 결과 건수를 기록 (사후 비교용).

> 결과가 0건이거나 매우 적어도 정상 — K-QMD가 한국어 검색에서 향상시키려는 케이스이므로.

- [ ] **Step 4: Node.js 버전 확인 (≥22 필요)**

```bash
node --version
```

Expected: `v22.x.x` 이상. v22 미만이면 plan 중단하고 Node 업그레이드 필요.

- [ ] **Step 5: 디스크 여유 공간 확인 (~2GB+ 필요)**

```bash
df -h $HOME | head -2
```

Expected: Available 컬럼이 5GB 이상이면 안전 (모델 ~2GB + Kiwi ~95MB + 인덱스).

---

## Task 2: PATH 충돌 처리 (Homebrew qmd 제거)

목표: npm 설치한 kqmd가 충돌 없이 `qmd` 명령으로 잡히도록 Homebrew qmd를 제거한다.

**Files:** 없음 (시스템 변경)

- [ ] **Step 1: Homebrew qmd unlink (안전한 1차 시도)**

```bash
brew unlink qmd
```

Expected: `Unlinking /opt/homebrew/Cellar/qmd/...` 메시지. 실패해도 다음 단계로 진행 가능.

- [ ] **Step 2: qmd 명령이 사라졌는지 확인**

```bash
which qmd 2>&1
command -v qmd 2>&1
```

Expected: 에러 또는 빈 출력 (PATH에서 사라짐). 만약 여전히 잡히면 다른 위치에 qmd가 있다는 뜻 → Step 3으로 강제 제거.

- [ ] **Step 3: (필요 시) Homebrew qmd 완전 제거**

만약 Step 2에서 여전히 qmd가 잡히면:

```bash
brew uninstall qmd
which qmd 2>&1
```

Expected: `Uninstalling /opt/homebrew/Cellar/qmd/...` 후 `which qmd` 에러.

> Brewfile 자동 업데이트 hook이 있으므로 commit 시 Brewfile에서 qmd가 제거됨. 이는 의도된 동작.

---

## Task 3: K-QMD 설치 및 검증

목표: npm으로 kqmd를 글로벌 설치하고 `qmd` 명령이 K-QMD 구현으로 동작하는지 확인한다.

**Files:** 없음 (npm 글로벌 설치)

- [ ] **Step 1: kqmd 글로벌 설치**

```bash
npm install -g kqmd
```

Expected: `added N packages` 또는 유사 메시지. 에러 없이 종료.

- [ ] **Step 2: 설치 위치/버전 확인**

```bash
which qmd
qmd --version
npm list -g kqmd 2>&1 | head -5
```

Expected:
- `which qmd` → `/opt/homebrew/bin/qmd` 또는 `~/.npm-global/bin/qmd` (npm prefix에 따라)
- `qmd --version` → kqmd 버전 문자열 (1.1.5와 다름)
- `npm list -g kqmd` → `kqmd@x.y.z` 표시

- [ ] **Step 3: 서브명령 호환성 빠른 점검**

```bash
qmd --help | head -30
qmd query --help 2>&1 | head -10
qmd update --help 2>&1 | head -5
qmd embed --help 2>&1 | head -5
qmd collection list 2>&1 | head -5
qmd mcp --help 2>&1 | head -5
```

Expected: 각 명령이 에러 없이 도움말 출력. 6개 모두 통과해야 함 (skill에서 사용하는 서브명령들).

> 하나라도 실패하면 K-QMD가 약속한 drop-in이 깨진 것 → Failure Condition. 롤백 검토.

---

## Task 4: 인덱스 재생성

목표: K-QMD가 사용하는 Qwen3 임베딩으로 인덱스를 재생성한다.

**Files:** 없음 (qmd 데이터 디렉토리 변경)

- [ ] **Step 1: qmd update 실행 (메타데이터/문서 인덱싱)**

```bash
qmd update
```

Expected: 진행 메시지 후 "indexed N files" 또는 유사 출력. 에러 없이 종료. 첫 실행 시 Kiwi 모델 자동 다운로드 (~95MB).

- [ ] **Step 2: qmd embed 실행 (Qwen3 임베딩 생성)**

```bash
qmd embed
```

Expected: 첫 실행 시 Qwen3 모델 자동 다운로드 (~2GB) → 임베딩 진행. 진행 시간은 세션 파일 양과 네트워크에 따라 5-30분.

> 시간이 걸리는 단계이므로 다른 작업과 병행 가능. 완료 시까지 기다린 후 다음 step.

- [ ] **Step 3: 인덱스 상태 사후 확인**

```bash
qmd collection list 2>&1
```

Expected: Task 1 Step 2와 동일한 컬렉션이 존재하고, Files 수가 비슷하거나 더 많음 (감소하면 인덱스 손실 의심).

---

## Task 5: Smoke Test (한국어 검색 품질 확인)

목표: K-QMD의 한국어 강점 패턴이 실제로 동작하는지 확인하고 baseline과 비교한다.

**Files:** 없음 (검색 실행만)

- [ ] **Step 1: 동일 쿼리로 사후 결과 기록**

```bash
qmd-search "보안 취약점" 2>/dev/null | head -20 > /tmp/qmd-after-1.txt
qmd-search "테스트 커버리지" 2>/dev/null | head -20 > /tmp/qmd-after-2.txt
qmd-search "Jenkins 파이프라인" 2>/dev/null | head -20 > /tmp/qmd-after-3.txt
wc -l /tmp/qmd-after-*.txt
```

Expected: 각 파일에 검색 결과 기록됨.

- [ ] **Step 2: Baseline과 사후 결과 비교**

```bash
diff /tmp/qmd-baseline-1.txt /tmp/qmd-after-1.txt | head -30
diff /tmp/qmd-baseline-2.txt /tmp/qmd-after-2.txt | head -30
diff /tmp/qmd-baseline-3.txt /tmp/qmd-after-3.txt | head -30
```

Expected: 결과가 동일하거나 (이미 충분히 잘 찾았던 경우), 사후가 더 많거나 (한국어 강점 발현). 사후가 의미 있게 적으면 Failure Condition.

- [ ] **Step 3: 긴 한국어 자연어 쿼리 smoke test**

```bash
qmd-search "보안 취약점 스캔은 어떻게 동작해" 2>/dev/null | head -20
```

Expected: 1건 이상 결과 출력. 0건이면 K-QMD의 query rescue가 동작하지 않은 것 → 인덱스 상태 재점검.

- [ ] **Step 4: skill 호출 회귀 점검 (수동)**

다음 명령으로 wrapper와 skill 의존성이 정상인지 확인:

```bash
bash ~/dotfiles/bin/qmd-search "테스트" 2>&1 | head -10
```

Expected: 에러 없이 결과 출력. 이는 `find-session`, `agf`, `recall` skill이 정상 동작함을 의미함 (모두 같은 wrapper 사용).

---

## Task 6: 메모리 파일 작성

목표: 미래 세션이 "qmd 명령은 K-QMD 백엔드"임을 인지할 수 있도록 reference 메모를 추가한다.

**Files:**
- Create: `~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md`
- Modify: `~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md` (Reference 섹션에 인덱스 1줄 추가)

- [ ] **Step 1: 신규 메모 파일 작성**

`~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md` 파일 생성, 다음 내용:

```markdown
---
name: reference_kqmd_backend
description: qmd 명령은 K-QMD (drop-in replacement) 백엔드로 동작하며 Korean-aware 검색을 제공
type: reference
---

# K-QMD 백엔드

## 사실

`qmd` 명령은 [K-QMD](https://github.com/jylkim/kqmd) drop-in replacement로 동작 중. 2026-05-02 npm으로 설치 (`npm install -g kqmd`). Homebrew qmd는 제거됨.

## 강점 (활용 시)

- **복합어 검색**: "보안취약점", "테스트커버리지" 같은 붙여쓰기 한국어
- **한영 혼합**: "Jenkins파이프라인", "Grafana대시보드"
- **긴 한국어 자연어 쿼리**: "보안 취약점 스캔은 어떻게 동작해" 같은 긴 plain query
- **Adaptive query ranking**: 쿼리 유형에 따라 ranking 전략 자동 조정 (`--explain`으로 근거 확인)
- **Search-assist query rescue**: hybrid query가 놓친 한국어 문서를 보조 신호로 보강

## 임베딩 모델

K-QMD는 Qwen3 임베딩으로 고정 (한국어 품질 우선). 이전 qmd 인덱스는 2026-05-02 재생성됨.

## 참조

- 명령어 wrapper: `~/dotfiles/bin/qmd-search`
- 사용 skill: `find-session`, `agf`, `recall`
- 설계 문서: `~/dotfiles/docs/superpowers/specs/2026-05-02-kqmd-migration-design.md`

## 롤백 방법

문제 발생 시:
\`\`\`bash
npm uninstall -g kqmd
brew install qmd
qmd update && qmd embed
\`\`\`
```

> 위 코드 블록의 escape된 백틱(`\`\`\``)은 markdown 인라인 표현용. 실제 파일에는 일반 백틱으로 작성.

- [ ] **Step 2: 파일 작성 검증**

```bash
ls -la ~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md
head -5 ~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md
```

Expected: 파일 존재. frontmatter `name: reference_kqmd_backend`, `type: reference` 확인.

- [ ] **Step 3: MEMORY.md Reference 섹션에 인덱스 1줄 추가**

`~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md` 파일의 `## Reference` 섹션 (현재 `reference_vault_intelligence_plans.md`, `reference_delegation_template.md` 항목 아래)에 다음 1줄 추가:

```markdown
- [kqmd-backend](reference_kqmd_backend.md) — qmd 명령은 K-QMD drop-in 백엔드 (2026-05-02 설치, Qwen3 임베딩, Korean-aware 검색)
```

- [ ] **Step 4: MEMORY.md 갱신 검증**

```bash
grep -A 1 'kqmd-backend' ~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md
wc -l ~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md
```

Expected: grep 결과 1줄, 파일 라인 수가 이전보다 1 증가 (또는 그 근처).

---

## Task 7: Brewfile 변경 commit

목표: Task 2에서 발생한 Brewfile 변경(qmd 제거)을 commit한다.

**Files:**
- Modify: `Brewfile` (Task 2의 부수 효과로 갱신됨)

> Plan 문서 자체는 plan 작성 직후 별도 commit됨 (이 task 외부). 메모리 파일은 dotfiles repo 외부(`~/.claude/projects/...`)이므로 dotfiles commit 대상이 아님.

- [ ] **Step 1: 변경 파일 확인**

```bash
cd ~/dotfiles
git status --short
```

Expected: `M Brewfile` (Task 2에서 qmd 제거됨). 다른 변경이 있으면 의도 밖이므로 점검 후 진행.

- [ ] **Step 2: Brewfile diff 확인 (qmd 제거만 있는지 검증)**

```bash
git diff Brewfile | head -20
```

Expected: `-brew "qmd"` 줄만 제거. 다른 변경 없으면 정상.

- [ ] **Step 3: Brewfile stage 및 commit**

```bash
cd ~/dotfiles
git add Brewfile

tmpfile=$(mktemp)
printf 'chore(brew): qmd 제거 (K-QMD npm 패키지로 교체)\n\nK-QMD가 drop-in replacement으로 qmd 명령을 그대로 노출하므로\nHomebrew 패키지를 제거. 설치/사용은 npm install -g kqmd.\n\nRefs: docs/superpowers/specs/2026-05-02-kqmd-migration-design.md\n' > "$tmpfile"
git commit -F "$tmpfile"
rm "$tmpfile"
```

Expected: pre-commit hooks 통과 후 `[main <hash>] chore(brew): ...` 메시지. 1 file changed (Brewfile).

- [ ] **Step 4: commit 검증**

```bash
git log --oneline -3
git show HEAD --stat
```

Expected: 최신 commit이 Brewfile만 변경. plan/spec commit은 이전 위치에 존재.

---

## Self-Review Checklist (이미 완료)

**1. Spec coverage**:
- [x] 설치: Task 3
- [x] 버전 확인: Task 1 Step 1, Task 3 Step 2
- [x] 인덱스 재생성: Task 4
- [x] smoke test: Task 5
- [x] 메모리 1줄 추가: Task 6 (실제로는 신규 파일 + MEMORY.md 인덱스 1줄)
- [x] PATH 충돌 처리: Task 2 (spec의 Error Handling 항목 대응)
- [x] 가역성/롤백: Task 6 메모 내 롤백 명령 + spec Rollback Plan

**2. Placeholder scan**: TBD/TODO 없음. 모든 명령어와 메모 내용 인라인.

**3. Type/path consistency**: 메모리 경로(`~/.claude/projects/-Users-msbaek-dotfiles/memory/`)와 신규 파일명(`reference_kqmd_backend.md`)이 모든 task에서 일치.

**4. 명령어 일관성**: `qmd update`, `qmd embed`, `qmd collection list`, `qmd-search`가 spec의 무변경 wrapper 호출과 정합.

---

## Failure Path (Rollback Procedure)

다음 중 하나 발생 시 즉시 롤백:
- Task 3 Step 3에서 서브명령 호환성 실패
- Task 5 Step 2에서 검색 결과가 의미 있게 악화
- Task 5 Step 3에서 긴 한국어 쿼리가 0건

```bash
npm uninstall -g kqmd
brew install qmd
qmd update && qmd embed
qmd --version  # 1.1.5 복귀 확인
```

이후 Task 6의 메모리 파일은 삭제하고 MEMORY.md 인덱스 1줄도 제거. dotfiles commit은 revert (`git revert HEAD`).
