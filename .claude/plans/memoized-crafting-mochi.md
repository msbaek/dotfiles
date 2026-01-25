# Skill 생성 계획: batch-summarize-urls

## 목표
URL 목록을 입력받아 각 URL에 대해 서브 에이전트를 병렬로 실행하여 `/obsidian:summarize-article` 커맨드를 실행하는 skill 생성

## Skill 개요 (확정)

### 이름
`batch-summarize-urls` ✅

### 위치
`/Users/msbaek/.claude/commands/obsidian/batch-summarize-urls.md` ✅

### 핵심 기능
1. URL 목록을 인자로 받음 (줄바꿈 또는 공백으로 구분)
2. 각 URL에 대해 Task tool을 사용하여 서브 에이전트 생성
3. 각 서브 에이전트가 Skill tool로 `/obsidian:summarize-article` 실행
4. **병렬 실행**: 모든 Task tool 호출을 단일 메시지에서 수행

## 구현 계획

### Step 1: Skill 파일 생성
`/Users/msbaek/.claude/commands/obsidian/batch-summarize-urls.md` 파일 생성

### Step 2: YAML Frontmatter 작성
```yaml
---
argument-hint: "[url1] [url2] ..."
description: "URL 목록을 받아 각 URL에 대해 서브 에이전트를 병렬로 실행하여 obsidian 문서 생성"
---
```

### Step 3: 본문 작성 - 핵심 지시사항

```markdown
# Batch Summarize URLs - $ARGUMENTS

여러 URL을 병렬로 처리하여 각각 Obsidian 문서를 생성합니다.

## 처리 프로세스

1. $ARGUMENTS에서 URL 목록 추출
2. **반드시 단일 메시지에서 모든 Task tool 호출 수행** (병렬 처리)
3. 각 Task tool 호출 시:
   - subagent_type: "general-purpose"
   - prompt: 해당 URL에 대해 Skill tool로 /obsidian:summarize-article 실행 지시
4. 모든 서브 에이전트 완료 대기
5. 결과 요약 출력

## 중요 사항

- **병렬 실행 필수**: 모든 URL은 동시에 처리되어야 함
- 각 서브 에이전트는 독립적으로 /obsidian:summarize-article 실행
- 생성된 문서 목록을 최종 보고
```

## 참고 파일

| 파일 | 용도 |
|------|------|
| `/Users/msbaek/.claude/commands/obsidian/summarize-article.md` | 호출할 기존 skill |
| `/Users/msbaek/.claude/commands/obsidian/batch-process.md` | 유사 패턴 참고 (Tmux 방식) |
| `/Users/msbaek/.claude/skills/skill-creator/` | skill-creator 가이드 |

## 예상 사용 예시

```bash
/obsidian:batch-summarize-urls https://medium.com/article1 https://medium.com/article2 https://medium.com/article3
```

## 체크리스트

- [ ] skill 파일 생성
- [ ] YAML frontmatter 작성
- [ ] 병렬 처리 지시사항 명확히 기술
- [ ] Task tool + Skill tool 조합 사용법 명시
- [ ] 테스트 실행
