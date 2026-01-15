---
name: daily-work-logger
description: |
  매일 아침 업무 시작 전 어제 작업 내역을 정리하여 Daily Note에 반영.
  미팅 노트, 기술 문서, 어제 수정된 문서에서 업무 관련 내용 추출.
  coffee-time은 제외 (weekly-newsletter에서 사용).
  "어제 작업 정리해줘", "daily log", "업무 내역 정리" 등의 요청 시 자동 적용.
---

# Daily Work Logger Skill

## 개요

매일 아침 업무 시작 전 실행하여 어제 작성/수정된 문서들에서 **업무 수행 관련 내용**을 추출하고 해당 날짜의 Daily Note에 반영하는 skill.

## 실행 시점

- **실행**: 매일 아침 업무 시작 전
- **대상**: 어제 작성/수정된 문서
- **출력**: `notes/dailies/YYYY-MM-DD.md` (어제 날짜)

## 경로 정보

| 항목 | 경로 |
|------|------|
| vault | `~/DocumentsLocal/msbaek_vault/` |
| dailies | `~/DocumentsLocal/msbaek_vault/notes/dailies/` |
| 미팅 노트 | `notes/dailies/YYYY-MM-DD-*.md` |
| 기술 문서 | `001-INBOX/`, `003-RESOURCES/` |

**참고**: coffee-time은 이 skill에서 제외 (weekly-newsletter에서만 사용)

## 실행 단계

### Step 1: 어제 날짜 계산

```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d)
echo "대상 날짜: $YESTERDAY"
```

### Step 2: 어제 수정된 파일 탐색

```bash
# 어제 수정된 파일 찾기 (coffee-time 제외)
find ~/DocumentsLocal/msbaek_vault -name "*.md" \
  -newermt "$YESTERDAY" ! -newermt "$(date +%Y-%m-%d)" \
  ! -path "*/coffee-time/*"

# 미팅 노트 확인
ls ~/DocumentsLocal/msbaek_vault/notes/dailies/${YESTERDAY}-*.md 2>/dev/null
```

### Step 3: 주요 문서 읽기

1. **미팅 노트**: `notes/dailies/YYYY-MM-DD-*.md`
   - 예: `2026-01-14-AWS Account Manager 미팅 정리.md`
2. **기술 문서**: `001-INBOX/`, `003-RESOURCES/` 폴더의 수정된 문서
3. **기타**: vault 전체에서 어제 수정된 문서

### Step 4: 업무 관련 내용 추출

**추출 기준:**
| 포함 | 제외 |
|------|------|
| 후속 액션 / TODO | 개인 학습 메모 |
| 미팅 결정사항 | 기술 인사이트 (newsletter용) |
| 업무 적용 검토 항목 | 리더십 토론 내용 |
| 일정 관련 사항 | 외부 공유용 내용 |

### Step 5: Daily Note 업데이트

**파일**: `notes/dailies/YYYY-MM-DD.md` (어제 날짜)

**추가 구조** (기존 내용 유지, 중복 확인 후 추가):
```markdown
---

## [미팅/작업명] - 후속 액션

### 후속 일정
- [ ] 액션 1
- [ ] 액션 2

### 검토 영역

| 영역 | 내용 |
|------|------|
| 영역1 | 설명 |

### 기대 효과
- 효과 1
- 효과 2

### 참고
- 상세 내용: [[관련 문서]]
```

## 중복 확인 규칙

1. 기존 Daily Note 읽기
2. 추가하려는 내용이 이미 존재하는지 확인
3. 중복되는 내용은 추가하지 않음
4. 기존 내용과 연관된 새 정보만 추가

## 자주 사용하는 명령어

```bash
# 어제 날짜 확인
date -v-1d +%Y-%m-%d

# 어제 수정된 파일 (coffee-time 제외)
find ~/DocumentsLocal/msbaek_vault -name "*.md" -mtime -1 -mtime +0 ! -path "*/coffee-time/*"

# 어제 미팅 노트 확인
ls ~/DocumentsLocal/msbaek_vault/notes/dailies/$(date -v-1d +%Y-%m-%d)-*.md 2>/dev/null

# 어제 Daily Note 확인
cat ~/DocumentsLocal/msbaek_vault/notes/dailies/$(date -v-1d +%Y-%m-%d).md
```

## 흐름 예시

```
월요일 아침 실행 시:
├── 대상 날짜: 금요일 (주말 제외 시 금요일)
├── 탐색 문서:
│   ├── notes/dailies/2026-01-17-*.md (미팅 노트)
│   ├── 001-INBOX/ 수정 문서
│   └── 003-RESOURCES/ 수정 문서
├── 추출 내용: 업무 후속 액션, 미팅 결정사항
└── 출력: notes/dailies/2026-01-17.md 업데이트
```

## 관련 Skill

- `weekly-newsletter`: 토요일 오전 뉴스레터 생성 (이 skill의 출력 참조)
- `obsidian-vault`: vault 작업 기본 가이드
