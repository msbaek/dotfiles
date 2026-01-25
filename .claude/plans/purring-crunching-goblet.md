# batch-summarize-urls.md 세션 연속성 기능 추가

## 목표
세션이 고갈되어도 다음 세션에서 이어서 작업할 수 있도록 계획 파일 기반 진행 상황 추적 기능 추가

## 수정 대상
- `/Users/msbaek/dotfiles/.claude/commands/obsidian/batch-summarize-urls.md`

## 핵심 결정사항 (사용자 확인 완료)

| 항목 | 결정 |
|------|------|
| 계획 파일 위치 | `.claude/batch-progress/` |
| 재개 방식 | 파일 경로 직접 전달 |
| 처리 방식 | **3개씩 병렬 처리** → 완료 후 다음 3개 (배치 순차) |

## 수정 내용

### 1. 처리 프로세스 변경

**변경 흐름:**
1. 인자 분석 (URL 목록 vs 계획 파일 경로)
2. 새 요청이면 → 계획 파일 생성 (`batch-YYYYMMDD-HHMMSS.md`)
3. 기존 계획 파일이면 → 미완료 항목 파악
4. **계획 파일 위치를 사용자에게 출력**
5. 3개씩 병렬 처리 (완료 시 각각 체크)
6. 다음 3개 처리 (반복)
7. 전체 완료 후 결과 요약

### 2. 계획 파일 형식

```markdown
# Batch Summarize Progress

생성 시간: YYYY-MM-DD HH:MM:SS
총 URL 수: N개

## 처리 목록

- [ ] https://example.com/article1
- [ ] https://example.com/article2
- [x] https://example.com/article3 → 00 - Inbox/제목.md

## 실패 항목

- https://example.com/failed → 에러 메시지
```

### 3. 인자 처리 로직

- `$ARGUMENTS`가 `.md`로 끝나면 → 계획 파일 재개
- 그 외 → URL 목록으로 파싱하여 새 계획 파일 생성

### 4. 추가할 주요 지침

1. 계획 파일 생성 후 **경로를 반드시 출력**
2. 3개 URL 배치 완료 시마다 **계획 파일 업데이트**
3. 완료된 항목은 `[x]`로 표시하고 생성된 문서 경로 추가
4. 실패 시 "실패 항목" 섹션에 기록

## 검증 방법

1. 여러 URL로 스킬 실행 → 계획 파일 생성 및 경로 출력 확인
2. 진행 중 계획 파일 확인 → 체크박스 업데이트 확인
3. 세션 재개 테스트: `/obsidian:batch-summarize-urls .claude/batch-progress/batch-xxx.md`
