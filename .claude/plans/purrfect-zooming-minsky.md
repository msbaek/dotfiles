# DB 스크럽 계획 (2025년 이전 데이터 삭제 후 진행)

## 전략 변경
~~배치 처리~~ → **2025년 이전 데이터 삭제 후 스크럽**

## 예상 효과

| 테이블 | 현재 건수 | 삭제 후 예상 | 감소율 |
|--------|-----------|--------------|--------|
| SELL_DELIY_ADDR | 22,853,774 | ~2,000,000 | ~91% |
| SELL_DELIY_ADDR_ADD | 21,873,299 | ~2,000,000 | ~91% |
| REVIEWS | 12,094 | ~1,200 | ~90% |

**USER, USER_DELIY_ADDR**: 마스터 테이블이므로 삭제하지 않음

---

## 실행 순서

### Phase 1: 현재 상태 확인
```sql
-- MySQL 접속 후
\. 00_analyze.sql
```
→ 이미 완료됨

### Phase 2: 2025년 이전 데이터 삭제

**기존 파일 사용**: `01_delete_old_data.sql`

```sql
\. 01_delete_old_data.sql
```

이 파일의 동작:
1. 삭제 예정 건수 확인 (SELECT)
2. SELL_DELIY_ADDR_ADD 삭제 (자식 먼저)
3. SELL_DELIY_ADDR 삭제 (부모)
4. REVIEWS 삭제
5. 삭제 후 건수 확인

**주의**: DELETE도 대용량이면 타임아웃 가능
- SELL_DELIY_ADDR_ADD: ~2천만 건 삭제
- SELL_DELIY_ADDR: ~2천만 건 삭제

타임아웃 발생 시 → DELETE도 LIMIT으로 배치 처리 필요

### Phase 3: 스크럽 실행

삭제 후 남은 데이터는 ~200만 건이므로 단일 UPDATE 가능:

```sql
-- USER는 이미 완료됨 (820만 건, 33분)

-- 남은 핵심 테이블 (삭제 후 소량)
\. 02_scrub_hmmall_core.sql

-- 추가 테이블
\. 03_scrub_hmmall_extra.sql

-- capybara 테이블
\. 04_scrub_capybara.sql
```

### Phase 4: 검증
```sql
\. 05_verify.sql
```

---

## 주의 사항

### 1. DELETE 타임아웃 대비

만약 `01_delete_old_data.sql` 실행 중 타임아웃 발생 시:

```sql
-- LIMIT으로 배치 삭제 (반복 실행)
DELETE sda FROM hmmall.SELL_DELIY_ADDR_ADD sda
INNER JOIN hmmall.SELL_DELIY_ADDR sd ON sda.SELL_DADDR_NO = sd.SELL_DADDR_NO
WHERE sd.REG_DT < '2025-01-01'
LIMIT 500000;

-- 영향 받은 행이 0이 될 때까지 반복
```

### 2. USER 테이블 상태

- USER 테이블은 이미 스크럽 완료 (33분)
- 02_scrub_hmmall_core.sql 재실행해도 무해 (동일 값으로 다시 UPDATE)

### 3. 삭제 순서 중요

```
1. SELL_DELIY_ADDR_ADD (자식) 먼저
2. SELL_DELIY_ADDR (부모) 나중
```

역순 삭제 시 참조 무결성 문제 가능

---

## 현재 진행 상태

- [x] 00_analyze.sql - 완료
- [x] USER 스크럽 - 완료 (33분)
- [ ] **01_delete_old_data.sql** - 다음 실행
- [ ] 02_scrub_hmmall_core.sql (USER 제외 테이블)
- [ ] 03_scrub_hmmall_extra.sql
- [ ] 04_scrub_capybara.sql
- [ ] 05_verify.sql

---

## 수정 필요 사항

### 02_scrub_hmmall_core.sql 수정 검토

USER 테이블은 이미 완료되었으므로, 필요시 USER UPDATE 부분을 주석 처리하여 중복 실행 방지 가능 (선택사항)

---

## 검증 방법

```sql
-- 삭제 후 건수 확인
SELECT COUNT(*) FROM hmmall.SELL_DELIY_ADDR;  -- ~200만 예상
SELECT COUNT(*) FROM hmmall.SELL_DELIY_ADDR_ADD;  -- ~200만 예상

-- 스크럽 후 검증
\. 05_verify.sql
-- 모든 unprocessed = 0 이어야 정상
```
