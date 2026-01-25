# Backlog.md Skill 개선 계획: 세션 연속성 및 리뷰 워크플로우

## 수정 대상 파일

`/Users/msbaek/dotfiles/.claude/skills/backlog-md/SKILL.md`

## 추가될 내용 (마크다운)

---

## Session Continuity & Review Workflow

### Task Completion Checkpoint

타스크 1개가 완료될 때마다 **반드시** 다음을 수행:

#### 1. Backlog Task 업데이트

```bash
# 구현 노트에 진행 내용 기록
backlog task edit <ID> --append-notes $'## Session Progress\n- 완료된 항목\n- 남은 이슈\n- 다음 단계'

# AC 체크 (완료된 것만)
backlog task edit <ID> --check-ac <완료된 AC 번호들>
```

#### 2. Plan 파일 업데이트 (있는 경우)

- `~/.claude/plans/` 아래 plan 파일에 진행 상황 반영
- 완료된 단계 체크, 다음 단계 명시

#### 3. 사용자 리뷰 요청

타스크가 완료되면 **반드시** 사용자에게 리뷰를 요청한다:

```
---
## 타스크 완료 리뷰 요청

**타스크**: [제목] (ID: [ID])

### 완료 내용
- [완료된 작업 요약]

### 다음 선택:
1. ✅ 다음 타스크 진행 - "다음"
2. 🔄 수정 요청 - 수정 내용 설명
3. ⏸️ 세션 종료 - "종료"
---
```

### User Response Handling

| 응답 | 액션 |
|-----|------|
| "다음", "진행" | 다음 backlog 타스크로 이동 |
| 수정 요청 | 현재 타스크 수정 후 재리뷰 |
| "종료", "stop" | 세션 종료 절차 실행 |

### Session End Procedure

세션 종료 시:

```bash
# 1. 진행 상황 저장
backlog task edit <ID> --append-notes $'## Session End\n- 마지막 작업: [내용]\n- 다음 시작점: [내용]'

# 2. 상태를 In Progress로 유지 (미완료 시)
backlog task edit <ID> -s "In Progress"
```

- plan 파일에도 동일하게 현재 상태와 다음 시작점 기록
- 다음 세션에서 바로 이어갈 수 있는 정보 포함

---

## 수정 위치

- SKILL.md 파일 끝부분 (Common Patterns 섹션 뒤)에 새 섹션 추가
- 기존 "Definition of Done" 섹션에 1줄 추가: `8. ✅ 사용자 리뷰 완료`

## 예상 변경

- 추가: 약 60줄
- 기존 수정: 1줄
