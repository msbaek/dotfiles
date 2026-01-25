# 5개 URL Obsidian 문서 생성 계획

## 목표
5개의 Medium 아티클을 병렬로 처리하여 Obsidian 문서로 변환

## 처리할 URL 목록

| # | URL | 예상 주제 |
|---|-----|-----------|
| 1 | https://medium.com/@ilyas.ibrahim/how-i-made-claude-code-agents-coordinate-100-and-solved-context-amnesia-5938890ea825 | Claude Code Agent 협업 및 컨텍스트 관리 |
| 2 | https://medium.com/coding-nexus/a-new-agent-memory-system-just-dropped-and-it-finally-fixes-what-weve-been-getting-wrong-fc84589f75ca | AI Agent 메모리 시스템 |
| 3 | https://medium.com/@r0r1/ai-code-review-with-claude-skills-from-diy-to-team-ready-636966cb8e36 | Claude Skills를 활용한 AI 코드 리뷰 |
| 4 | https://medium.com/javarevisited/the-command-pattern-simplified-how-modern-java-21-25-makes-it-elegant-3d9891227cc7 | Java 21-25 Command Pattern |
| 5 | https://medium.com/@PowerUpSkills/the-free-tool-that-replaces-cleanmymac-daisydisk-and-appcleaner-8dc8e069cb53 | Mac 정리 도구 |

## 실행 전략

### 병렬 처리
- 5개의 Task agent를 동시에 실행
- 각 agent는 `obsidian:summarize-article` 스킬 호출
- Playwright 도구로 Medium 페이지 접근 (로그인 회피)

### 문서 생성 규칙
- 저장 위치: `001-INBOX/`
- 파일명: 문서 제목 기반 (한글 또는 영문)
- YAML frontmatter 포함 (id, aliases, tags, author, created_at, source)
- 이미지: ATTACHMENTS/ 폴더에 저장
- 태그: hierarchical tag 형식 (최대 6개)

### 번역/요약 규칙
- 약 4000자 내외의 상세 요약
- 기술 용어는 영어 원문 병기
- 구조: Highlights → Detailed Summary → Conclusion

## 실행 명령

```
# 5개 Task agent 병렬 실행
Task(subagent_type="general-purpose", prompt="Skill obsidian:summarize-article [URL]")
```

## 예상 결과물

| # | 예상 파일명 |
|---|-------------|
| 1 | Claude-Code-Agent-Coordination-Context-Amnesia.md |
| 2 | AI-Agent-Memory-System.md |
| 3 | AI-Code-Review-Claude-Skills.md |
| 4 | Command-Pattern-Java-21-25.md |
| 5 | Free-Mac-Cleaning-Tool.md |

## 주의사항
- Medium 페이지는 paywall이 있을 수 있음 → Playwright로 접근
- 이미지 누락 없이 모두 저장
- 태그는 의미 중심 (디렉토리 기반 태그 금지)
