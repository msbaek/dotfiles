# Sub-agent 위임 패턴 일괄 적용 설계서

> Date: 2026-05-01
> Status: draft
> Trigger commit: c3b9e99 (`docs(obsidian): sonnet-4.6 sub-agent 동기 위임 패턴 명시`)

## 1. Goal (testable)

사용자가 만든 모든 slash command와 skill에 대해, **frontmatter `model:` 필드가 main context에서 무시되는 문제**를 해결하기 위해 sub-agent 동기 위임 패턴을 일괄 적용한다.

**완료 조건**:
- `~/.claude/commands/` (사용자 작성분, plugin 제외) 모든 일회성 작업이 sub-agent 위임으로 실행됨
- `~/.claude/skills/` (사용자 작성분, plugin/symlink 제외) 모든 일회성 작업이 sub-agent 위임으로 실행됨
- 인터랙티브 작업은 main context 유지 + 의도가 주석으로 명시됨
- 표준 boilerplate가 단일 reference 파일로 관리되어 향후 변경 시 한 곳만 수정

## 2. Constraints (non-negotiable)

| 항목 | 제약 |
|------|------|
| 적용 범위 | `~/.claude/commands/` 및 `~/.claude/skills/` 사용자 작성분만 |
| 제외 | symlink (`skillify`, `find-skills`, `dr-jskill`), plugin namespace (`obsidian:*`, `msbaek-tdd:*`, `superpowers:*`, `augmented:*`, `tdp:*`, `code-review:*`, `pr-review-toolkit:*`, `plugin-dev:*`, `claude-md-management:*`, `hookify:*`, `playground:*`, `frontend-design:*`, `atlassian:*`) |
| stow 호환 | 모든 변경은 dotfiles repo 내에서 발생 (`stow .`로 자동 배포) |
| Plugin 파일 직접 수정 금지 | CLAUDE.md 규칙 (`~/.claude/CLAUDE.md`) |
| 인터랙티브 작업 | sub-agent 위임 안 함 — main context에서 multi-turn 대화 유지 |

## 3. 패턴 (Architecture)

### 3.1 표준 템플릿 위치

`~/.claude/templates/delegation.md` (신규 디렉토리, dotfiles repo의 `.claude/templates/`)

### 3.2 템플릿 변형

| 변형 | 모델 | 동기/백그라운드 | 용도 예시 |
|------|------|----------------|----------|
| A | sonnet | 동기 | 텍스트 변환·요약·분석 (commit, wrap-up, meeting-minutes 등) |
| B | haiku | 동기 | 단순 변환·조회 (markitdown, skills-audit, vis 등) |
| C | sonnet | 백그라운드 | 장기 작업 (summarize-article, summarize-youtube 등) |
| D | haiku | 백그라운드 | (현재 사용처 없음 — 변형만 정의) |

### 3.3 호출 파일 reference 형태

각 command/skill 파일의 `## 실행 모델 (필수)` 섹션:

```markdown
## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=$ARGUMENTS, 옵션=`--dry-run`, `--recursive`)

main context에서 직접 실행 금지.
```

### 3.4 인터랙티브 파일 처리

frontmatter `model:` 라인 제거 + 헤더에 다음 주석 추가:

```markdown
<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->
```

## 4. 분류 매트릭스

### 4.1 Commands (29개)

| 카테고리 | 파일 수 | 파일 |
|---------|--------|------|
| **A** (동기+sonnet) | 10 | `commit`, `wrap-up`, `meeting-minutes`, `check-security`, `obsidian/batch-process`, `obsidian/create-presentation`, `obsidian/related-contents`, `obsidian/translate-article`, `obsidian/translate-youtube`, `obsidian/weekly-social-posts` |
| **B** (동기+haiku) | 5 | `conventional-review`, `markitdown-convert`, `skills-audit`, `skills-catalog`, `obsidian/vault-query` |
| **C** (백그라운드+sonnet) | 3 | `coffee-time`, `obsidian/summarize-article`, `obsidian/summarize-youtube` |
| **I** (인터랙티브) | 6 | `askUserQuestion`, `code-review-walkthrough`, `my-developer`, `project-overview`, `skills-curate`, `update-claude-md` |
| **N** (변경 없음) | 3 | `vis-backlink-toggle` (단순 bash), `obsidian/shared-rules` (reference doc), `obsidian/tagging-example` (예시) |
| **✓** (이미 적용) | 2 | `obsidian/add-tag`, `obsidian/add-tag-and-move-file` |

### 4.2 Skills (24개)

| 카테고리 | 파일 수 | 파일 |
|---------|--------|------|
| **A** (동기+sonnet) | 4 | `architecture-diagram`, `graphify`, `capture-research`, `claude-code-release-tracker` |
| **B** (동기+haiku) | 6 | `agf`, `recall`, `vis`, `vis-backlink-status`, `obsidian-jobs`, `extract-sql-log` |
| **I** (인터랙티브) | 4 | `brunch-writer`, `write-in-my-voice`, `find-session`, `session-handoff` |
| **N** (변경 없음) | 10 | 이미 sub-agent dispatch: `daily-work-logger`, `weekly-newsletter`, `humanize-korean`, `vis-backlink-trigger`. Reference doc: `gh`, `prompt-contracts`, `obsidian-vault`, `obsidian-document-workflow`, `java-structural-ops`, `react-best-practices` |

총 변경 대상: **38 파일** (commands 24 + skills 14) + 신규 1 (templates).

## 5. Commit 구조 (rollback-friendly)

| # | 범위 | 파일 수 | 메시지 |
|---|------|--------|--------|
| 1 | `templates/delegation.md` 신규 | 1 | `feat(claude/templates): sub-agent delegation 표준 템플릿 추가` |
| 2 | Commands 변형 A | 10 | `refactor(claude/commands): 동기+sonnet sub-agent 위임 패턴 적용` |
| 3 | Commands 변형 B | 5 | `refactor(claude/commands): 동기+haiku sub-agent 위임 패턴 적용` |
| 4 | Commands 변형 C | 3 | `refactor(claude/commands): 백그라운드+sonnet 위임 패턴 명시` |
| 5 | Commands 인터랙티브 | 6 | `refactor(claude/commands): 인터랙티브 명령 model 필드 제거 + 주석` |
| 6 | Skills 변형 A | 4 | `refactor(claude/skills): 동기+sonnet sub-agent 위임 패턴 적용` |
| 7 | Skills 변형 B | 6 | `refactor(claude/skills): 동기+haiku sub-agent 위임 패턴 적용` |
| 8 | Skills 인터랙티브 | 4 | `refactor(claude/skills): 인터랙티브 skill model 필드 제거 + 주석` |
| 9 | Spec doc | 1 | `docs(superpowers): sub-agent 위임 패턴 spec 추가` |

총 9 commits. 각 commit 후 `stow` 부작용 없는지 빠른 확인 (symlink 무결성).

## 6. Verification

### 6.1 기계적 (각 commit 후)

- 모든 변형 A/B/C 파일에 `templates/delegation.md` reference 문자열 존재
- 인터랙티브 파일에 `^model:` 라인 부재 + `<!-- Execution: interactive` 주석 존재
- frontmatter YAML 문법 무결 (`yq` 또는 awk 검증)
- `stow .` 후 symlink 정상

### 6.2 행동 (사후 모니터링)

- 실제 슬래시 커맨드/skill 실행 시 sub-agent 위임 동작 확인은 일상 사용 중 token usage 모니터링
- 한 commit씩 push 후 부작용 발견 시 즉시 revert

## 7. Failure Conditions

다음 중 하나라도 발생 시 해당 commit revert + spec 재검토:

1. **Symlink 깨짐**: `stow .` 후 `~/.claude/templates/delegation.md` symlink 미생성
2. **Frontmatter 파싱 오류**: 변경된 파일의 YAML frontmatter가 yq/awk로 파싱 안 됨
3. **인터랙티브 파일에서 sub-agent 호출 발생**: 사용자가 인터랙티브 명령 실행 시 multi-turn 대화 흐름 끊김
4. **Reference 누락**: 변형 A/B/C 적용 파일이 `templates/delegation.md` reference 없이 `## 실행 모델` 섹션만 가짐
5. **Plugin 영역 침범**: 변경 사항이 `~/.claude/plugins/` 하위 파일을 건드림

## 8. 범위 제외 (이번에 안 다룸)

- N 그룹 중 reference doc skills(`gh`, `prompt-contracts`, `obsidian-vault`, `obsidian-document-workflow`, `java-structural-ops`, `react-best-practices`): frontmatter `model:` 자체가 무의미하지만 변경 사유가 약함 → 차후 별도 commit으로 검토
- Plugin 영역 (`obsidian:*`, `msbaek-tdd:*` 등): CLAUDE.md 규칙대로 제외
- Symlink skill (`skillify`, `find-skills`, `dr-jskill`): 외부 repo이므로 제외
- 변형 D (백그라운드+haiku): 현재 사용처 없음 — 템플릿에 정의만 두고 적용은 미래 작업

## 9. 예상 분량

- 38 파일 × ~5줄 boilerplate 평균 = ~190줄 추가
- 인터랙티브 10 파일 × ~3줄 = ~30줄 변경
- `templates/delegation.md` 신규 ~50줄
- 총 ~270줄 변경 (대부분 단순 패턴 적용)

## 10. 다음 단계

이 spec 승인 후 `superpowers:writing-plans` skill로 implementation plan 작성 → `subagent-driven-development` 또는 `executing-plans`로 실행.
