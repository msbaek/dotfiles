# Skill & MCP 정리 설계서

> Date: 2026-04-29
> Status: approved
> Branch: `chore/cleanup-skill-mcp-2026-04-29`

## 1. 목표

- **(b) 세션 시작 토큰 절감**: MCP 서버 도구 schema/instructions가 매 세션 system prompt에 주입되는 비용 감소
- **(c) 유지보수성**: dead/stale/duplicate 항목 식별 및 제거

## 2. 결정 사항

| 항목 | 결정 |
|------|------|
| 정리 방식 | 하이브리드 — audit 초안 → 사용자 라벨링 (keep/remove) |
| 정리 순서 | MCP → Plugin → 로컬 Skill |
| 백업 전략 | git 별도 브랜치 + 복구 가이드 markdown (항목별 개별 복원) |
| 보호 목록 | 사전 지정 없음 — audit 후보에서 사용자가 keep 지정 |
| 머지 방식 | `git merge --no-ff` (이력 보존) |

## 3. 대상 파일

### MCP 설정 (5개)
| 파일 | git 추적 | 비고 |
|------|---------|------|
| `~/dotfiles/.claude/mcp.json` | O | dotfiles repo |
| `~/dotfiles/.claude/settings.json` | O | dotfiles repo (MCP 아님, 참조용) |
| `~/.claude/settings.json` | X | global settings — 스냅샷으로 보존 |
| `~/.ai/mcp/mcp.json` | X | 스냅샷으로 보존 |
| `~/.claude/plugins/installed_plugins.json` | X | 스냅샷으로 보존 |

추가 MCP 파일 (vault, bin, ai-dev-kit):
- `~/DocumentsLocal/msbaek_vault/.mcp.json`
- `~/bin/.mcp.json`
- `~/.ai-dev-kit/repo/.mcp.json`

### Plugin
- `~/.claude/plugins/installed_plugins.json` 기준

### 로컬 Skill
- `~/.claude/skills/` (62개 디렉토리)

## 4. 커밋 구조

```
chore/cleanup-skill-mcp-2026-04-29
  ├─ commit 1: chore: 정리 전 스냅샷 저장
  │   └─ docs/snapshots/2026-04-29/ 에 git 밖 파일 사본
  ├─ commit 2: chore: MCP 서버 정리
  │   └─ mcp.json 파일에서 제거 대상 항목 삭제
  ├─ commit 3: chore: Plugin 정리
  │   └─ installed_plugins.json 업데이트
  ├─ commit 4: chore: 로컬 Skill 정리
  │   └─ ~/.claude/skills/ 에서 제거 대상 삭제
  └─ commit 5: docs: 정리 복구 가이드 작성
      └─ docs/cleanup-recovery-guide.md
```

## 5. 단계별 프로세스

### 5.1 사전 준비
1. `chore/cleanup-skill-mcp-2026-04-29` 브랜치 생성
2. `docs/snapshots/2026-04-29/` 에 git 외부 파일 스냅샷 저장
3. commit 1

### 5.2 MCP 정리
1. 모든 mcp.json 파일 파싱 → 서버 매핑 테이블 생성:

| 서버명 | 등록 위치 | 도구 수 | 상태 | 판정 |
|--------|----------|---------|------|------|
| (예) browsermcp | dotfiles/.claude/mcp.json | 12 | DEAD | REMOVE |

2. 상태 판단 기준:
   - **DEAD**: disconnect / startup 실패
   - **DORMANT**: 등록돼 있지만 PostToolUse 로그 기록 기간 내 사용 0회 (로그 시작일 이전은 판단 유보, 사용자 체감으로 보완)
   - **ACTIVE**: 로그 기간 내 1회 이상 사용 또는 사용자가 "쓴다"고 확인
   - **DUPLICATE**: 같은 서버가 여러 파일에 등록

3. DEAD + DORMANT → 삭제 후보로 사용자에게 제시
4. 사용자 keep/remove 라벨링
5. remove 항목의 원래 JSON 블록을 복구 가이드용으로 보존
6. mcp.json에서 제거 → commit 2

### 5.3 Plugin 정리
1. `installed_plugins.json` 파싱 → plugin별 테이블:

| Plugin 명 | Skill 수 | MCP 포함 | 판정 |
|-----------|---------|---------|------|
| (예) databricks | 26 | O (80+ tools) | REMOVE 후보 |

2. 판정 기준:
   - **PROTECT**: 사전 제외 (superpowers, obsidian 등은 후보에 넣되 표시)
   - **REMOVE**: 도메인 자체 미사용
   - **TRIM**: plugin 유지, MCP만 비활성화

3. 사용자 라벨링 → 실행 → commit 3

### 5.4 로컬 Skill 정리
1. `~/.claude/skills/` 스캔 + `skills-audit` 데이터 결합:

| Skill 명 | 유형 | Symlink | 판정 |
|----------|------|---------|------|
| (예) find-session-workspace | local | N | DUPLICATE |

2. 판정 기준:
   - **DUPLICATE**: plugin과 로컬 양쪽 존재
   - **ORPHAN**: symlink 깨짐
   - **STALE**: plugin이 이미 제공하는 구버전
   - **DORMANT**: 사용 기록 없음

3. 사용자 라벨링 → 실행 → commit 4

### 5.5 복구 가이드
1. `docs/cleanup-recovery-guide.md` 작성
   - 전체 복원: `git revert <merge-commit>`
   - MCP 서버별: 원래 JSON 블록 + 등록 파일 경로
   - Plugin별: marketplace ID + 설치 명령
   - Skill별: `git checkout <commit> -- <path>` 명령어
2. commit 5

### 5.6 마무리
1. main에 `git merge --no-ff` 머지
2. Claude 재시작 → 토큰 절감 확인
3. journal 기록

## 6. 제약 조건

- **제거만, 수정 없음**: 기존 skill/MCP의 내용을 고치지 않음. 있거나 없거나.
- **git 외부 파일은 스냅샷으로만 백업**: `~/.ai/mcp/mcp.json` 등은 dotfiles git에 없으므로 사본 저장
- **Plugin 파일 직접 편집 최소화**: `installed_plugins.json` 외에 plugin 내부 파일은 건드리지 않음
- **복구 가이드가 SSOT**: 제거한 모든 항목의 복원 정보는 이 문서에 집중

## 7. Failure Conditions

- 복구 가이드에 누락된 항목이 있으면 실패 — 제거한 모든 항목이 가이드에 있어야 함
- 스냅샷과 실제 파일이 불일치하면 실패 — 스냅샷 시점의 정확한 사본이어야 함
- 사용자 라벨링 없이 제거하면 실패 — 모든 제거는 사용자 승인 후
