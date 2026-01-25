# Plan: sales-analysis-plan.md 개선 및 태스크 리스트 변환

## 요약
- **반영 범위**: 전체 반영 (오타 수정 + 누락 단계 추가 + 진행 상태 관리)
- **데이터 저장**: JSON 파일

---

## 수정 대상 파일
`/Users/msbaek/git/kt4u/sales-analysis/.claude/tasks/sales-analysis-plan.md`

---

## 변경 내용

### 1. 오타 수정
- `playright` → `playwright`
- `{message*id}*{index}.png` → `{message_id}_{index}.png`

### 2. 전체 구조 변경
기존 번호 목록을 Phase별 체크박스 목록으로 재구성

---

## 최종 태스크 리스트 (적용될 내용)

```markdown
## 작업 절차

### Phase 0: 환경 준비
- [ ] `.gitignore`에 `data/`, `browser_data/` 추가
- [ ] `data/raw/` 디렉토리 구조 생성
- [ ] `browser_data/` 디렉토리 생성 (세션 저장용)

### Phase 1: Teams 채널 접속
- [ ] Playwright로 Teams 채널 URL 이동
- [ ] "Use the web app instead" 버튼 클릭 (표시되는 경우)
- [ ] 로그인 필요 시 `.env`의 TEAMS_USER_ID, TEAMS_PASSWORD로 로그인
- [ ] 로그인 성공 후 `storage_state` 저장 (`browser_data/teams_auth.json`)
- [ ] 채널 접근 불가 시 사용자에게 수동 작업 요청

### Phase 2: 메시지 로드
- [ ] `networkidle` 상태까지 대기
- [ ] 위로 스크롤하여 과거 메시지 로드
- [ ] 스크롤 종료 조건: `scrollTop === 0` 이후 추가 메시지 로드 없으면 종료
- [ ] 스크롤 간 랜덤 지연 (500ms~2000ms) - Rate Limiting 방지

### Phase 3: 메시지 파싱
- [ ] message_id 추출
- [ ] 제목 추출
- [ ] 본문 텍스트/HTML 추출
- [ ] `<time>` 태그 `datetime` 속성에서 게시 시간 추출
- [ ] 연도 포함 여부로 올해 데이터 필터링
- [ ] 메시지 본문 내 이미지 URL 추출
- [ ] 첨부파일 링크 수집
- [ ] 수집된 메시지를 `data/raw/messages.json`에 저장

### Phase 4: 이미지 다운로드
- [ ] 인라인 이미지 URL에서 다운로드
- [ ] `data/raw/{date}/images/`에 저장
- [ ] 파일명: `{message_id}_{index}.png` 형식
- [ ] 재시도 로직 구현 (최대 3회, exponential backoff)
- [ ] 이모티콘/프로파일 이미지 필터링 (크기 < 100px 또는 URL 패턴)
- [ ] 다운로드 간 지연 (Rate Limiting 방지)

### Phase 5: Excel 다운로드
- [ ] SharePoint 링크 감지 및 처리
- [ ] 일반 URL HTTP 다운로드
- [ ] `data/raw/{date}/excel/`에 저장
- [ ] 파일명 sanitize 처리
- [ ] 재시도 로직 구현 (최대 3회)
- [ ] 다운로드 성공/실패 로그 기록

### Phase 6: 진행 상태 관리
- [ ] `data/checkpoint.json`에 마지막 수집 message_id 저장
- [ ] 재실행 시 checkpoint 이후 메시지만 수집
- [ ] 세션 종료 전 checkpoint 업데이트
```

---

## 검증 방법
1. 수정 후 마크다운 렌더링에서 체크박스 정상 표시 확인
2. 각 항목을 `[x]`로 변경하여 완료 표시 가능 여부 테스트
3. Git diff로 변경 내용 확인
