# Custom Claude Code Subagents 아티클 요약 계획

## 작업 개요
Medium 아티클 "Custom Subagents: 90% of Developers Set Them Up Wrong"을 한국어로 번역/요약하여 Obsidian 문서로 생성

## 수집된 정보

### 원문 정보
- **제목**: Custom Subagents: 90% of Developers Set Them Up Wrong
- **부제**: After debugging 47 subagent failures, I found the same 4 configuration mistakes. — the complete fix guide.
- **저자**: Reza Rezvani (CTO @ HealthTech startup in Berlin)
- **URL**: https://alirezarezvani.medium.com/custom-subagents-90-of-developers-set-them-up-wrong-7328341a4a57
- **작성일**: 1 day ago (약 2026-01-18)
- **읽기 시간**: 10 min

### 핵심 내용 요약

**4가지 주요 실수와 해결책:**

1. **Mistake 1: 모든 도구를 모든 에이전트에게 허용**
   - 문제: tools 필드 생략 시 모든 도구 상속 → 컨텍스트 오염, 보안 위험
   - 해결: 명시적 tool allowlist 사용 (deny-all 기본)

2. **Mistake 2: Claude가 매칭할 수 없는 모호한 description**
   - 문제: "Helps with code stuff" 같은 모호한 설명
   - 해결: 액션 동사 + 구체적 도메인 + "Use PROACTIVELY" / "MUST BE USED" 트리거 키워드

3. **Mistake 3: 리서치 작업으로 인한 컨텍스트 오염**
   - 문제: 탐색 작업이 메인 컨텍스트에 쌓임
   - 해결: `context: fork` 사용으로 격리

4. **Mistake 4: Claude Code가 서브에이전트를 무시**
   - 문제: Claude가 직접 처리하려는 성향
   - 해결: CLAUDE.md에 명시적 위임 규칙 + SubagentStop hooks

**엔터프라이즈 워크플로우 패턴:**
- Sequential Pipeline with Human Gates (PubNub 패턴)
- Parallel Specialists (Zach Wills 패턴)

### 이미지
- 페이지 상단 헤더 이미지 (Gemini 3 Pro 생성)

## 생성할 문서

### 파일 경로
`/Users/msbaek/DocumentsLocal/msbaek_vault/001-INBOX/Custom-Subagents-90-of-Developers-Set-Them-Up-Wrong.md`

### 태그 설계 (6개 이내)
```yaml
tags:
  - ai/tools/claude-code/subagents
  - ai/agents/configuration-patterns
  - ai/agents/context-management
  - development/practices/tool-orchestration
  - patterns/workflow/pipeline-patterns
  - guide/troubleshooting
```

### YAML Frontmatter
```yaml
id: "Custom Subagents: 90% of Developers Set Them Up Wrong"
aliases: "커스텀 서브에이전트: 90%의 개발자가 잘못 설정하는 방법"
tags:
  - ai/tools/claude-code/subagents
  - ai/agents/configuration-patterns
  - ai/agents/context-management
  - development/practices/tool-orchestration
  - patterns/workflow/pipeline-patterns
  - guide/troubleshooting
author: reza-rezvani
created_at: 2026-01-19 12:30
related: []
source: https://alirezarezvani.medium.com/custom-subagents-90-of-developers-set-them-up-wrong-7328341a4a57
```

## 작업 단계

1. ~~페이지 접근 및 내용 읽기~~ (완료)
2. ~~태깅 규칙 확인~~ (완료)
3. 이미지 다운로드 (ATTACHMENTS 폴더로)
4. 한국어 번역 및 요약 문서 작성
5. Obsidian 문서 생성

## 실행 계획

Plan mode이므로 실제 파일 생성은 승인 후 진행합니다.
