# backlog-md Skill 수정 계획: 서브 에이전트 기반 태스크 실행

## 목표
태스크 실행 시 서브 에이전트(Task tool)를 사용하여 메인 컨텍스트의 토큰 사용량 최소화

## 현재 상태
- 파일: `~/.claude/skills/backlog-md/SKILL.md`
- 현재 방식: 모든 태스크 작업이 메인 컨텍스트에서 직접 실행
- 문제점: 여러 태스크 처리 시 컨텍스트 급격히 증가

## 수정 내용

### 1. 새 섹션 추가: "Sub-Agent Task Execution" (위치: Task Workflow 섹션 앞)

```markdown
## Sub-Agent Task Execution

### 원칙
**모든 태스크 실행은 서브 에이전트를 통해 수행한다.**

메인 컨텍스트는 태스크 조율자(orchestrator) 역할만 수행:
- 태스크 목록 조회
- 다음 태스크 결정
- 사용자와 커뮤니케이션
- 서브 에이전트 결과 요약 전달

### 서브 에이전트 호출 패턴

태스크 시작 시:

\`\`\`
Task tool 호출:
- subagent_type: "general-purpose"
- description: "Execute backlog task [ID]"
- prompt: |
    Execute backlog task [ID]: [제목]

    ## Task Details
    [backlog task <ID> --plain 결과]

    ## Instructions
    1. AC 분석 및 구현 계획 수립
    2. 코드 구현/수정
    3. 테스트 실행 및 검증
    4. AC 체크: backlog task edit <ID> --check-ac <완료된 번호>
    5. 노트 추가: backlog task edit <ID> --append-notes "진행 내용"

    ## Return Format
    작업 완료 후 다음 형식으로 반환:
    - 완료된 AC 목록
    - 수정된 파일 목록
    - 테스트 결과
    - 미해결 이슈 (있는 경우)
\`\`\`

### 메인 컨텍스트 워크플로우

\`\`\`
1. backlog task list -a @me -s "In Progress" --plain  # 현재 태스크 확인
2. backlog task <ID> --plain                           # 태스크 상세 조회
3. Task tool로 서브 에이전트 생성 (태스크 전체 위임)
4. 서브 에이전트 결과 수신
5. 사용자에게 완료 리뷰 요청
6. 사용자 응답에 따라 다음 태스크 또는 종료
\`\`\`
```

### 2. "Task Completion Checkpoint" 섹션 수정

기존 내용에 서브 에이전트 결과 처리 추가:

```markdown
### Task Completion Checkpoint

타스크 1개가 완료될 때마다:

#### 서브 에이전트 결과 처리
서브 에이전트가 반환한 결과를 바탕으로:
1. 완료 상태 확인
2. 사용자에게 요약 전달

#### 사용자 리뷰 요청
(기존 내용 유지)
```

### 3. "Tips" 섹션에 추가

```markdown
11. **서브 에이전트 사용**: 태스크 실행은 항상 Task tool로 위임하여 메인 컨텍스트 경량화
```

## 수정 파일
- `~/.claude/skills/backlog-md/SKILL.md`

## 실행 방식
- **동기 실행**: 서브 에이전트 완료까지 대기 후 결과 확인
- `run_in_background: false` (기본값)

## 예상 효과
- 메인 컨텍스트: 태스크 조회, 결과 요약만 유지
- 서브 에이전트: 구현, 테스트, AC 체크 등 상세 작업 수행
- 여러 태스크 연속 처리 시에도 메인 컨텍스트 크기 일정 유지

## Uncertainty Map
- **서브 에이전트 컨텍스트 전달**: 현재 프로젝트 컨텍스트가 서브 에이전트에게 충분히 전달되는지 실제 테스트 필요
- **에러 핸들링**: 서브 에이전트 실패 시 복구 전략이 명시적으로 정의되지 않음
- **backlog CLI 접근성**: 서브 에이전트가 backlog CLI에 접근 가능한지 확인 필요
