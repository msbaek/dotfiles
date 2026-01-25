# Claude-Code-Spec-Based-Development-Workflow.md를 AI 활용 기법에 통합

## 현황 분석

### 발견된 문서들
1. **원본 문서**: `003-RESOURCES/AI/CLAUDE-CODE/Claude-Code-Spec-Based-Development-Workflow.md`
   - Thariq(Anthropic 개발자)가 공유한 AskUserQuestionTool 기반 스펙 작성 워크플로우
   - 태그: `development/practices/spec-driven`, `ai/claude-code/workflow`

2. **AI 활용 기법 MOC**: `003-RESOURCES/AI/AI-Practice-Techniques/_AI-Practice-MOC.md`
   - 핵심 기법 #7: `[[techniques/스펙-주도-개발-spec-driven-development]]`

3. **기법 노트**: `003-RESOURCES/AI/AI-Practice-Techniques/techniques/스펙-주도-개발-spec-driven-development.md`
   - 일반적인 설명만 있음
   - Claude-Code-Spec-Based-Development-Workflow.md에 대한 참조 **없음**

### 현재 문제
- Claude-Code-Spec-Based-Development-Workflow.md가 AI 활용 기법 문서 체계에 **연결되어 있지 않음**
- 스펙 주도 개발 기법 노트에서 실제 워크플로우 예시 문서를 참조하지 않음

---

## 실행 계획

### 1단계: 스펙-주도-개발 기법 노트 업데이트
**파일**: `003-RESOURCES/AI/AI-Practice-Techniques/techniques/스펙-주도-개발-spec-driven-development.md`

추가할 내용:
- `🔗 관련 문서` 섹션에 Claude-Code-Spec-Based-Development-Workflow.md 링크 추가
- 또는 새로운 `📚 참고 자료` 섹션 생성

### 2단계: (선택) MOC Claude Code 섹션에 추가
**파일**: `003-RESOURCES/AI/AI-Practice-Techniques/_AI-Practice-MOC.md`

`## 도구별 분류 > ### Claude Code` 섹션에 해당 문서 링크 추가 검토

---

## 수정 예시

### 스펙-주도-개발-spec-driven-development.md 수정안

```markdown
## 🔗 관련 문서

- [[_AI-Practice-MOC|AI 활용 기법 MOC]]
- [[ai-assisted-development|AI-Assisted Development 카테고리]]
- [[../../../AI/CLAUDE-CODE/Claude-Code-Spec-Based-Development-Workflow|Claude Code Spec 기반 개발 워크플로우]] ← 추가

## 📚 참고 자료  ← 새 섹션 추가

### 실무 적용 가이드
- [[../../../AI/CLAUDE-CODE/Claude-Code-Spec-Based-Development-Workflow|Claude Code Spec 기반 개발 워크플로우]]
  - AskUserQuestionTool을 활용한 인터뷰 기반 스펙 작성
  - 40개 이상의 심층 질문으로 상세 스펙 완성
  - "인터뷰 → 스펙 완성 → 새 세션에서 실행" 3단계 프로세스
```

---

## 검증 방법

1. Obsidian에서 `스펙-주도-개발-spec-driven-development.md` 열기
2. 관련 문서 링크가 정상적으로 연결되는지 확인
3. Graph View에서 두 문서 간 연결 확인

---

## Uncertainty Map

- **링크 경로**: 상대 경로 `../../../AI/CLAUDE-CODE/...`가 정확한지 Obsidian에서 확인 필요
- **기존 스타일 유지**: 다른 기법 노트들의 형식과 일관성 유지 필요
