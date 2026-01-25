# Superpowers 활용 가이드 및 설정 플랜

## 개요

**목적**: obra/superpowers 도구를 현재 Claude Code/Desktop 사용 패턴에 최적화하여 활용

**현재 상태**:
- superpowers v4.0.3 이미 설치됨 (`~/.claude/plugins/cache/claude-plugins-official/superpowers/4.0.3/`)
- 기존 TDD 스킬 17개+ 보유 (tdd-red, tdd-green, tdd-blue 등)
- 다양한 커스텀 스킬 활용 중 (obsidian, jira, gh, brunch-writer 등)
- Hooks 시스템 구성됨 (PreToolUse 알림, bash 로깅, UserPromptSubmit)

---

## 1. Superpowers 핵심 기능 및 활용 시나리오

### 1.1 Brainstorming (`/superpowers:brainstorm`)

**기능**: 아이디어 정제, 대안 탐색, 설계 문서 생성

**활용 시나리오**:
- 신규 기능 개발 전 요구사항 명확화
- Obsidian vault 대규모 리팩토링 전 전략 수립
- 복잡한 데이터 파이프라인 설계

**AI-PROFILE.md 자동 주입 설정**:
```
# ~/.claude/CLAUDE.md에 추가
<brainstorming-context>
When using superpowers:brainstorm, automatically inject context from ~/git/aboutme/AI-PROFILE.md:
- 25년 경력 개발자 관점
- TDD/OOP 중심 설계 선호
- 단순성과 실용성 우선
</brainstorming-context>
```

### 1.2 Plan Writing (`/superpowers:write-plan`)

**기능**: 2-5분 단위 세부 작업으로 분해된 구현 계획 생성

**특징**:
- 각 작업에 정확한 파일 경로, 코드, 검증 단계 포함
- YAGNI, DRY 원칙 강조
- TDD RED-GREEN-REFACTOR 강제

### 1.3 Plan Execution (`/superpowers:execute-plan`)

**두 가지 모드**:
1. **subagent-driven-development**: 같은 세션에서 서브에이전트 활용
2. **executing-plans**: 별도 세션에서 배치 실행

**점진적 피드백 워크플로우** (사용자 요청 반영):
```
초기 3개 작업 실행 → 사용자 피드백 → 문제 없으면 자율 작업 진행
```

### 1.4 Test-Driven Development

**기존 TDD 스킬과의 통합**:
- superpowers의 TDD를 메인 워크플로우로 사용
- 기존 tdd-blue (Tidying)의 Kent Beck 스타일 리팩토링은 보조로 활용

**핵심 원칙**:
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
코드를 먼저 작성했다면? 삭제하고 처음부터.
```

### 1.5 Git Worktrees

**기능**: 격리된 개발 환경 자동 생성

**프로젝트별 전략 적용**:
- 개인 프로젝트: 자유로운 worktree 생성
- 업무 프로젝트: 기존 브랜치 전략 존중

---

## 2. Obsidian Vault 자동화 시나리오

### 2.1 태그 체계 재구성

**superpowers 활용**:
```
/superpowers:brainstorm
"7000+ 파일의 태그를 hierarchical 체계로 재구성하고 싶습니다.
현재 상태: 26개 태그만 사용 중, 대부분 태그 없음
목표: 검색과 Graph View 활용도 극대화"
```

**작업 분해 예시**:
1. 현재 태그 분석 (5분)
2. 태그 taxonomy 설계 (brainstorming 결과 기반)
3. 카테고리별 태그 적용 스크립트 생성
4. 003-RESOURCES 폴더부터 파일럿 적용
5. 결과 검증 후 전체 적용

### 2.2 MOC(Map of Content) 생성

**작업 분해 예시**:
1. 주요 주제 영역 식별 (TDD, Refactoring, AI, Architecture)
2. 각 영역별 핵심 노트 발견
3. MOC 템플릿 생성
4. 자동 링크 수집 스크립트 작성
5. MOC 노트 생성 및 연결

### 2.3 링크 그래프 강화

**Smart Connections 임베딩 활용**:
- `.smart-env/multi/*.ajson` 파일 분석
- 유사도 기반 관련 노트 발견
- 백링크/관련 콘텐츠 섹션 자동 추가

---

## 3. 설정 변경 사항

### 3.1 Hooks 우선순위 조정

**현재 hooks** (`~/.claude/settings.pro.json`):
- PreToolUse: terminal-notifier 알림 + bash 로깅
- Stop: 완료 알림
- UserPromptSubmit: ultrathink 스크립트

**superpowers hooks 활성화**:
superpowers는 자체 hooks를 제공하므로, 기존 알림 hooks는 유지하되 충돌 시 superpowers 우선

### 3.2 Verification Before Completion 강화

**추가 검증 단계**:
1. 테스트 실행 검증
2. plan/todo 문서 업데이트 확인
3. 세션 연속성을 위한 상태 저장

**설정 예시**:
```markdown
# 작업 완료 전 체크리스트
- [ ] 모든 테스트 통과
- [ ] plan 파일에 완료 상태 반영
- [ ] todo 목록 업데이트
- [ ] 다음 세션을 위한 컨텍스트 기록
```

### 3.3 위험 요소 완화

**컨텍스트 드리프트 방지**:
- 초기 2-3개 작업 후 피드백 루프 강제
- 각 작업 후 spec compliance 검증
- code quality 리뷰 단계 유지

**복구 용이성 확보**:
- git worktree로 격리
- 각 작업 단위 커밋
- 문제 발생 시 롤백 가능

---

## 4. 실행 계획

### Phase 1: 설정 업데이트 (선택적)

1. `~/.claude/CLAUDE.md`에 brainstorming 컨텍스트 추가
2. 기존 TDD 스킬 비활성화 또는 보조 역할로 전환
3. verification 체크리스트 추가

### Phase 2: 파일럿 테스트

**신규 기능 개발**:
```bash
# 작은 기능으로 시작
/superpowers:brainstorm
# 설계 승인 후
/superpowers:write-plan
# 계획 승인 후 (초기 3개 작업만)
/superpowers:execute-plan
```

**Obsidian 자동화**:
```bash
# 태그 체계 재구성 파일럿 (003-RESOURCES/TDD 폴더)
/superpowers:brainstorm
"003-RESOURCES/TDD 폴더 내 파일들의 태그를 hierarchical 체계로 재구성"
```

### Phase 3: 전체 적용

파일럿 결과 검토 후 전체 워크플로우 적용

---

## 5. 핵심 명령어 요약

| 명령어 | 용도 | 사용 시점 |
|--------|------|----------|
| `/superpowers:brainstorm` | 아이디어 정제, 설계 | 새 작업 시작 전 |
| `/superpowers:write-plan` | 세부 작업 분해 | 설계 승인 후 |
| `/superpowers:execute-plan` | 계획 실행 | 계획 승인 후 |

---

## 6. 기대 효과

1. **개발 생산성**: 2-5분 단위 작업으로 집중력 유지
2. **품질 보장**: TDD 강제, 2단계 코드 리뷰
3. **세션 연속성**: plan/todo 문서화로 중단 후 재개 용이
4. **위험 완화**: 점진적 피드백 루프, git worktree 격리

---

## Uncertainty Map

**낮은 확신 영역**:
- Hooks 간 충돌 가능성 - 실제 테스트 필요
- Smart Connections 임베딩 활용 범위 - 추가 분석 필요

**단순화된 부분**:
- superpowers 모든 스킬의 세부 동작
- 프로젝트별 git 전략 세부 사항

**추후 질문이 필요할 수 있는 부분**:
- 구체적인 신규 기능 개발 대상
- DataBricks 작업과의 연계 범위
