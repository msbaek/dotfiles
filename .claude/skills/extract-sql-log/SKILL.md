---
name: extract-sql-log
description: >
  서버 로그(ActionRunner/p6spy)에서 SQL 추출, 포맷팅, 마스킹 분석. 사용자가 Spring Boot 서버 로그를
  붙여넣고 "SQL 뽑아줘", "SQL 정리해줘", "로그에서 쿼리 추출", "마스킹 확인",
  "어떤 SQL이 실행됐는지 분석" 등을 요청할 때 반드시 이 스킬 사용.
  actionSet JSON, query(xxx) 포맷 SQL, p6spy 로그가 섞인 텍스트도 처리 가능.
---

# SQL Log Extractor

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 B 적용** — 단, `subagent_type`은 `general-purpose` 대신 **`sql-log-extractor`** 사용 (전용 sub-agent).
(model="haiku", run_in_background=false, args=skill 호출 인자, 옵션=`--all`, `--json`, `-o`)

main context에서 직접 실행 금지.

서버 로그에서 SQL을 추출하고 포맷팅하며 ISMS 마스킹 컴플라이언스를 분석하는 스킬.

## When to Use

- 사용자가 ActionRunner/p6spy 로그를 붙여넣고 SQL 정리 요청
- 서버 로그에서 INSERT/UPDATE/DELETE/SELECT 추출 필요
- 마스킹 데이터가 DB에 기록되는지 확인 필요
- UPSERT의 ON DUPLICATE KEY UPDATE에 마스킹 필드 포함 여부 점검

## Workflow

### Step 1: 로그를 임시 파일에 저장

사용자가 제공한 로그 텍스트를 임시 파일에 저장한다.

```bash
# 로그를 파일로 저장
cat > /tmp/sql_log_input.txt << 'LOGEOF'
... (user's log text) ...
LOGEOF
```

### Step 2: Python 파서 실행

이 스킬의 `scripts/extract_sql.py`를 사용해 기계적 파싱을 수행한다.

```bash
# INSERT/UPDATE/DELETE만 (기본)
python3 ~/.claude/skills/extract-sql-log/scripts/extract_sql.py /tmp/sql_log_input.txt

# 전체 DML 포함 (SELECT 포함)
python3 ~/.claude/skills/extract-sql-log/scripts/extract_sql.py --all /tmp/sql_log_input.txt

# JSON 출력 (프로그래밍 활용)
python3 ~/.claude/skills/extract-sql-log/scripts/extract_sql.py --json /tmp/sql_log_input.txt

# 파일로 저장
python3 ~/.claude/skills/extract-sql-log/scripts/extract_sql.py --all -o /tmp/sql_analysis.md /tmp/sql_log_input.txt
```

### Step 3: 분석 보강 (Claude 판단 영역)

Python 파서가 기계적 추출을 하고, Claude는 다음을 추가 분석한다:

1. **마스킹 데이터 판별**: `te**@`, `010****0000`, `*****` 같은 패턴이 INSERT/UPDATE 값에 있는지 확인.
   테스트 데이터(예: `테스트주소`, `01000000000`)와 마스킹 데이터를 구분.

2. **UPSERT 마스킹 필드 검증**: ON DUPLICATE KEY UPDATE 절에 마스킹 대상 필드가 포함되었는지 확인.
   INSERT에는 있어도 UPDATE에서 제외되어야 정상.

3. **데이터 흐름 추적**: SELECT에서 읽힌 마스킹 데이터가 FE를 거쳐 다시 INSERT/UPDATE로 돌아오는
   패턴 식별 (예: FE가 마스킹된 응답 데이터를 mutation에 그대로 전송).

4. **actionSet 컨텍스트**: 어떤 비즈니스 flow인지 (재발송, 주문나눔, 클레임 저장 등) 식별하여 의미 부여.

## Output Format

```markdown
# SQL Log Analysis — [Flow Name]

## ActionSet 1: [Description]
> baseParms: `KEY=VALUE, ...`
> actions: `action1, action2, ...`

### 1. query(query_id) — TYPE → TABLE_NAME [badges]

\```sql
-- query_id: xxx
-- table: TABLE_NAME
-- masking fields: [if applicable]
FORMATTED SQL HERE
\```

---

## Masking Analysis

| # | query_id | Table | Masking Fields | INSERT Value | In UPDATE? | Status |
|---|----------|-------|---------------|-------------|-----------|--------|
| 1 | m_xxx    | TABLE | FIELD1, FIELD2| test data   | excluded  | ✅ safe |

## Conclusion
[Overall assessment]
```

## Masking Fields Reference (thomas project)

| Table | Masking Fields |
|-------|---------------|
| SELL_DELIY_ADDR | ADDR1, ADDR2, RECIPIENT, RECIPIENT2, TEL, HP, SSN, SSN_ENC |
| SELL_DELIY_ADDR_ADD | PASS_NO, ACCT_NO, ACCT_NM, BIRTH |
| SELL_CER | TEL, HP, EMAIL |
| SELL / SELL_ADD | SSN, ACCT_NO |
| ONLINE_EVENT | USER_NM, CH_INFO, BIRTH, TEL |
| USER | USER_NM, EMAIL, TEL, HP |
| USER_DELIY_ADDR | ADDR1, ADDR2, RECIPIENT, TEL, HP |

## Badges

- 🔒 — SELECT가 마스킹 대상 필드 접근
- ⚠️ MASKED DATA — INSERT/UPDATE 값에 마스킹 패턴 감지
- ⚠️ VIOLATION — UPSERT UPDATE 절에 마스킹 필드 포함

## Notes

- p6spy 로그는 같은 쿼리를 여러 connection에서 중복 출력 → 자동 제거
- `m_user_action_merge`는 ActionRunner 자동 감사 로그 → 별도 표시
- `actionSetWithoutMasking()` 패턴 사용 여부도 코드 레벨에서 확인 권장
