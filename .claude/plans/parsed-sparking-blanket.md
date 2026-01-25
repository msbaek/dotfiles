# Plan: CLAUDE.md에 Skills 가이드 추가

## 목표
`/Users/msbaek/git/LLM/prompts/CLAUDE.md` 파일에 Claude Code Skills 생성 관련 가이드를 간략하게 추가합니다.

## 결정 사항
- **상세 수준**: 간략하게 (사용자 선택)
- **추가 위치**: Extension Development Guidelines 섹션

## 변경 계획

### 추가할 내용 (간략 버전)

**Extension Development Guidelines** 섹션의 기존 내용 뒤에 추가:

```markdown
- **Skills**: Claude가 자동으로 감지하여 적용하는 전문화된 지식 파일. 공식 문서: https://docs.anthropic.com/en/docs/claude-code/skills

### Skills 파일 위치

```
~/.claude/skills/my-skill/    # Personal (모든 프로젝트)
.claude/skills/my-skill/      # Project (해당 repository만)
```

### 기본 구조

```
my-skill/
├── SKILL.md              # 필수: 메인 가이드 (500줄 이내)
├── reference.md          # 선택: 상세 참고
└── scripts/              # 선택: 유틸리티 스크립트
```

### SKILL.md 템플릿

```yaml
---
name: skill-name-lowercase
description: "무엇을 하는지 + 언제 사용하는지 (트리거 키워드 포함)"
---

# Skill 제목

## 핵심 내용
...
```

### 프로젝트 예제
`claude/skills/` 디렉토리에서 실제 Skills 예제 참조
```

## 파일 변경 목록
- `/Users/msbaek/git/LLM/prompts/CLAUDE.md` (편집)
  - Extension Development Guidelines 섹션에 Skills 관련 내용 추가

## 구현 순서
1. CLAUDE.md 파일의 Extension Development Guidelines 섹션 찾기
2. 기존 Slash Commands, Sub-agents 링크 뒤에 Skills 내용 추가
