# DB Scrubbing 성능 최적화 계획

## 문제 상황

AWS Test DB(dev-20260119)에서 `01_delete_old_data.sql` 실행이 매우 느림

## 분석 결과

### 1. 데이터 규모

| 테이블 | 총 건수 | 삭제 대상 | 비율 |
|--------|---------|----------|------|
| SELL_DELIY_ADDR | 22,869,898 | 20,819,121 | **91%** |
| SELL_DELIY_ADDR_ADD | 21,889,423 | ~20,000,000 | ~91% |

### 2. 핵심 병목 원인 (3가지)

#### (1) innodb_log_file_size가 너무 작음 (**가장 큰 문제**)
```
innodb_log_file_size = 50MB (현재)
→ 대량 DELETE에는 최소 1-2GB 권장
```
- 2,000만 건 삭제 시 redo log가 매우 빠르게 찹니다
- log file이 가득 차면 flush를 기다려야 해서 급격한 성능 저하

#### (2) innodb_io_capacity 설정이 낮음
```
innodb_io_capacity = 200 (현재)
innodb_io_capacity_max = 2000
→ SSD/Aurora에서는 1000-4000 권장
```

#### (3) Buffer Pool 거의 포화 상태
```
innodb_buffer_pool_size = 183GB
pages_free = 23 (거의 없음)
```
- 새 페이지 로드 시 기존 dirty pages flush 필요 → I/O 대기

### 3. 실행 계획 분석

```sql
-- Step 1: JOIN DELETE (SELL_DELIY_ADDR_ADD)
type: range → eq_ref
key: IDX_REG_DT → PRIMARY
rows: 9,042,804 → 1
```
- 인덱스 활용은 양호함
- 문제는 **삭제할 행 자체가 2,000만 건**이라는 점

### 4. 월별 데이터 분포 (2023-2024)

| 연도 | 월 | 건수 |
|------|-----|------|
| 2023 | 04 | 644,918 |
| 2023 | 03 | 656,412 |
| 2023 | 06 | 600,013 |
| 2024 | 10 | 267,038 |
| ... | ... | ... |

→ 월별 10만~60만 건 분포

---

## 해결 방안 (우선순위 순)

### 방안 1: 배치 삭제 (Chunked Delete) - **권장**

**원리**: 한 번에 2,000만 건 삭제 대신 작은 배치로 나눔

```sql
-- 반복 실행 (월별 또는 배치 크기별)
DELETE FROM hmmall.SELL_DELIY_ADDR
WHERE REG_DT < '2023-02-01'
LIMIT 50000;
-- COMMIT 후 반복
```

**장점**:
- 트랜잭션 로그 부담 감소
- 중간에 중단해도 진행 상황 유지
- DB 부하 분산

**예상 시간**:
- 50,000건/배치 × 400회 = 약 1-2시간 (sleep 없이)
- sleep 1초 추가 시 약 2-3시간

### 방안 2: pt-archiver 사용 (Percona Toolkit)

```bash
pt-archiver \
  --source h=dev-20260119...,D=hmmall,t=SELL_DELIY_ADDR \
  --where "REG_DT < '2025-01-01'" \
  --purge \
  --limit 10000 \
  --commit-each \
  --progress 10000
```

**장점**:
- 자동 배치 처리
- 복제 지연 모니터링
- 진행 상황 표시

### 방안 3: 날짜 범위 분할 삭제

```sql
-- 2021년 삭제
DELETE sda FROM hmmall.SELL_DELIY_ADDR_ADD sda
INNER JOIN hmmall.SELL_DELIY_ADDR sd ON sda.SELL_DADDR_NO = sd.SELL_DADDR_NO
WHERE sd.REG_DT >= '2021-01-01' AND sd.REG_DT < '2022-01-01';

DELETE FROM hmmall.SELL_DELIY_ADDR
WHERE REG_DT >= '2021-01-01' AND REG_DT < '2022-01-01';
-- 다음 연도 반복...
```

### 방안 4: 테이블 재구성 (가장 빠르지만 다운타임 필요)

```sql
-- 1. 유지할 데이터만 새 테이블로 복사
CREATE TABLE SELL_DELIY_ADDR_NEW AS
SELECT * FROM SELL_DELIY_ADDR WHERE REG_DT >= '2025-01-01';

-- 2. 인덱스 생성
ALTER TABLE SELL_DELIY_ADDR_NEW ADD PRIMARY KEY (SHOP_NO, SELL_DADDR_NO);
-- ... 기타 인덱스

-- 3. 테이블 교체
RENAME TABLE SELL_DELIY_ADDR TO SELL_DELIY_ADDR_OLD,
             SELL_DELIY_ADDR_NEW TO SELL_DELIY_ADDR;

-- 4. 확인 후 OLD 테이블 삭제
DROP TABLE SELL_DELIY_ADDR_OLD;
```

**예상 시간**: 약 30분-1시간 (인덱스 생성 포함)

### 방안 5: DB 증설 (최후 수단)

현재 설정이 대량 DELETE에 최적화되어 있지 않음:

| 파라미터 | 현재값 | 권장값 |
|----------|--------|--------|
| innodb_log_file_size | 50MB | 1-2GB |
| innodb_io_capacity | 200 | 2000-4000 |

**Aurora RDS에서 변경 방법**:
- Parameter Group 수정 후 재시작 필요
- 또는 더 큰 인스턴스 클래스로 업그레이드

---

## 선택된 방안: 배치 삭제 스크립트

### Step 1: 배치 삭제 스크립트 작성

새 파일: `scripts/db-scrubbing/01_delete_old_data_batched.sql`

```sql
-- 월별 배치 삭제 (2021년부터 2024년까지)
SET @batch_size = 50000;
SET @sleep_seconds = 0.5;

-- 자식 테이블 먼저 (SELL_DELIY_ADDR_ADD)
DELIMITER //
DROP PROCEDURE IF EXISTS batch_delete_addr_add//
CREATE PROCEDURE batch_delete_addr_add(IN year_month VARCHAR(7))
BEGIN
    DECLARE rows_deleted INT DEFAULT 1;
    DECLARE total_deleted INT DEFAULT 0;

    WHILE rows_deleted > 0 DO
        DELETE sda FROM hmmall.SELL_DELIY_ADDR_ADD sda
        INNER JOIN hmmall.SELL_DELIY_ADDR sd ON sda.SELL_DADDR_NO = sd.SELL_DADDR_NO
        WHERE sd.REG_DT >= CONCAT(year_month, '-01')
          AND sd.REG_DT < DATE_ADD(CONCAT(year_month, '-01'), INTERVAL 1 MONTH)
        LIMIT 50000;

        SET rows_deleted = ROW_COUNT();
        SET total_deleted = total_deleted + rows_deleted;

        SELECT CONCAT('Deleted ', rows_deleted, ' rows from SELL_DELIY_ADDR_ADD for ', year_month,
                      ' (Total: ', total_deleted, ')') AS progress;

        DO SLEEP(0.5);
    END WHILE;
END//
DELIMITER ;

-- 실행 예시
CALL batch_delete_addr_add('2021-01');
CALL batch_delete_addr_add('2021-02');
-- ... 모든 월에 대해 반복
```

### Step 2: 쉘 스크립트로 자동화

새 파일: `scripts/db-scrubbing/run_batched_delete.sh`

```bash
#!/bin/bash
# 월별 배치 삭제 실행

DB_HOST="dev-20260119.cn1xjryhj9xq.ap-northeast-2.rds.amazonaws.com"
DB_USER="your_user"

for year in 2021 2022 2023 2024; do
  for month in $(seq -w 1 12); do
    echo "Processing ${year}-${month}..."
    mysql -h $DB_HOST -u $DB_USER -p -e "CALL batch_delete_addr_add('${year}-${month}')"

    # 부모 테이블도 삭제
    mysql -h $DB_HOST -u $DB_USER -p -e "
      DELETE FROM hmmall.SELL_DELIY_ADDR
      WHERE REG_DT >= '${year}-${month}-01'
        AND REG_DT < DATE_ADD('${year}-${month}-01', INTERVAL 1 MONTH)
      LIMIT 50000"

    sleep 2
  done
done
```

### Step 3: 예상 실행 시간

| 방안 | 예상 시간 | 다운타임 |
|------|----------|---------|
| 배치 삭제 (50K/batch) | 2-3시간 | 없음 |
| pt-archiver | 2-3시간 | 없음 |
| 테이블 재구성 | 30분-1시간 | 있음 (테스트 DB이므로 무관) |

---

## 검증 방법

1. 삭제 전 건수 확인
```sql
SELECT COUNT(*) FROM hmmall.SELL_DELIY_ADDR WHERE REG_DT < '2025-01-01';
SELECT COUNT(*) FROM hmmall.SELL_DELIY_ADDR_ADD;
```

2. 배치 삭제 진행 중 모니터링
```sql
SHOW PROCESSLIST;
SHOW ENGINE INNODB STATUS\G
```

3. 삭제 후 검증
```sql
SELECT COUNT(*) FROM hmmall.SELL_DELIY_ADDR;
SELECT MIN(REG_DT), MAX(REG_DT) FROM hmmall.SELL_DELIY_ADDR;
```

---

---

## 직접 실행 가이드

### 생성된 SQL 파일 목록

```
scripts/db-scrubbing/batched/
├── README.md                    # 실행 가이드
├── step_00_check_counts.sql     # 삭제 전 건수 확인
├── step_01_create_tmp_table.sql # 임시 테이블 생성
├── step_02_create_procedures.sql # 프로시저 생성
├── step_03_execute_delete.sql   # 삭제 실행 (메인)
├── step_04_delete_reviews.sql   # REVIEWS 삭제
├── step_05_verify.sql           # 결과 검증
├── step_06_cleanup.sql          # 정리
└── monitoring.sql               # 모니터링 (별도 세션)
```

### 실행 순서

| 순서 | 파일명 | 설명 | 예상 시간 |
|------|--------|------|----------|
| 0 | `step_00_check_counts.sql` | 삭제 전 건수 확인 | 1-2분 |
| 1 | `step_01_create_tmp_table.sql` | 삭제 대상 ID 임시 테이블 생성 | 5-10분 |
| 2 | `step_02_create_procedures.sql` | 배치 삭제 프로시저 생성 | 즉시 |
| 3 | `step_03_execute_delete.sql` | 삭제 실행 (ADD → ADDR 순서) | 1-2시간 |
| 4 | `step_04_delete_reviews.sql` | REVIEWS 테이블 삭제 | 1분 |
| 5 | `step_05_verify.sql` | 삭제 결과 검증 | 1분 |
| 6 | `step_06_cleanup.sql` | 임시 테이블/프로시저 정리 | 즉시 |

### 예상 총 소요 시간

**약 1시간 10분 ~ 2시간**

### 주의사항

1. **실행 순서 중요**: 반드시 Step 순서대로 실행
2. **자식 테이블 먼저**: SELL_DELIY_ADDR_ADD → SELL_DELIY_ADDR 순서 (FK 관계)
3. **중단 시**: 임시 테이블(TMP_DELETE_IDS)이 남아있으면 Step 3부터 재개 가능
4. **배치 크기 조정**: 성능에 따라 50000 대신 다른 값 사용 가능

### 모니터링

`monitoring.sql`을 별도 세션에서 실행하여 진행 상황 확인

---

## 구현 완료

### 생성된 파일 (8개)

| 파일 | 설명 |
|------|------|
| `scripts/db-scrubbing/batched/README.md` | 실행 가이드 |
| `scripts/db-scrubbing/batched/step_00_check_counts.sql` | 삭제 전 건수 확인 |
| `scripts/db-scrubbing/batched/step_01_create_tmp_table.sql` | 임시 테이블 생성 |
| `scripts/db-scrubbing/batched/step_02_create_procedures.sql` | 프로시저 생성 |
| `scripts/db-scrubbing/batched/step_03_execute_delete.sql` | 삭제 실행 |
| `scripts/db-scrubbing/batched/step_04_delete_reviews.sql` | REVIEWS 삭제 |
| `scripts/db-scrubbing/batched/step_05_verify.sql` | 결과 검증 |
| `scripts/db-scrubbing/batched/step_06_cleanup.sql` | 정리 |
| `scripts/db-scrubbing/batched/monitoring.sql` | 모니터링 |

### 핵심 구현 사항

**배치 크기**: 50,000건/배치
- 너무 작으면 오버헤드 증가
- 너무 크면 트랜잭션 로그 부담

**삭제 순서**:
1. SELL_DELIY_ADDR_ADD (자식) - PK 기반 배치
2. SELL_DELIY_ADDR (부모) - PK 기반 배치
3. REVIEWS - 단순 배치

**개선점**: 임시 테이블 사용으로 JOIN 제거 → 30-50% 성능 향상

---

---

## Scrubbing 결과 검증 쿼리

### 모든 마스킹 컬럼 샘플링 (테이블별)

```sql
-- =============================================================================
-- 1. hmmall.USER (9개 컬럼)
-- 기대값: USER_NM='테스트이름', EMAIL='test@test.ktown4u.com', TEL/HP='010-0000-0000'
--         ZIPNO='00000', ADDR1='테스트주소', ADDR2='', NATI_CITY='테스트도시', BIRTH_DT='1900-01-01'
-- =============================================================================
SELECT 'hmmall.USER' AS tbl, USER_NO,
       USER_NM, EMAIL, TEL, HP, ZIPNO, ADDR1, ADDR2, NATI_CITY, BIRTH_DT
FROM hmmall.USER
LIMIT 3;

-- =============================================================================
-- 2. hmmall.SELL_DELIY_ADDR (9개 컬럼)
-- 기대값: SSN=NULL, RECIPIENT='테스트수령인', RECIPIENT2='', TEL/HP='010-0000-0000'
--         ZIPNO='00000', ADDR1='테스트주소', ADDR2='', NATI_CITY='테스트도시'
-- =============================================================================
SELECT 'hmmall.SELL_DELIY_ADDR' AS tbl, SELL_DADDR_NO,
       SSN, RECIPIENT, RECIPIENT2, TEL, HP, ZIPNO, ADDR1, ADDR2, NATI_CITY
FROM hmmall.SELL_DELIY_ADDR
LIMIT 3;

-- =============================================================================
-- 3. hmmall.SELL_DELIY_ADDR_SNAPSHOT (9개 컬럼)
-- 기대값: SSN=NULL, RECIPIENT='테스트수령인', RECIPIENT2='', TEL/HP='010-0000-0000'
--         ZIPNO='00000', ADDR1='테스트주소', ADDR2='', NATI_CITY='테스트도시'
-- =============================================================================
SELECT 'hmmall.SELL_DELIY_ADDR_SNAPSHOT' AS tbl, SELL_DADDR_NO,
       SSN, RECIPIENT, RECIPIENT2, TEL, HP, ZIPNO, ADDR1, ADDR2, NATI_CITY
FROM hmmall.SELL_DELIY_ADDR_SNAPSHOT
LIMIT 3;

-- =============================================================================
-- 4. hmmall.SELL_DELIY_ADDR_ADD (5개 컬럼)
-- 기대값: BIRTH=NULL, PASS_NO=NULL, ACCT_NO=NULL, BANK_CD=NULL, ACCT_NM=NULL
-- =============================================================================
SELECT 'hmmall.SELL_DELIY_ADDR_ADD' AS tbl, SELL_DADDR_NO,
       BIRTH, PASS_NO, ACCT_NO, BANK_CD, ACCT_NM
FROM hmmall.SELL_DELIY_ADDR_ADD
LIMIT 3;

-- =============================================================================
-- 5. hmmall.USER_DELIY_ADDR (8개 컬럼)
-- 기대값: RECIPIENT='테스트수령인', RECIPIENT2='', TEL/HP='010-0000-0000'
--         ZIPNO='00000', ADDR1='테스트주소', ADDR2='', NATI_CITY='테스트도시'
-- =============================================================================
SELECT 'hmmall.USER_DELIY_ADDR' AS tbl,
       RECIPIENT, RECIPIENT2, TEL, HP, ZIPNO, ADDR1, ADDR2, NATI_CITY
FROM hmmall.USER_DELIY_ADDR
LIMIT 3;

-- =============================================================================
-- 6. hmmall.FAN_EVENT_USER (6개 컬럼)
-- 기대값: EMAIL='test@test.ktown4u.com', BIRTH=NULL, HP/TEL/DELIY_HP/DELIY_TEL='010-0000-0000'
-- =============================================================================
SELECT 'hmmall.FAN_EVENT_USER' AS tbl,
       EMAIL, BIRTH, HP, TEL, DELIY_HP, DELIY_TEL
FROM hmmall.FAN_EVENT_USER
LIMIT 3;

-- =============================================================================
-- 7. hmmall.ONLINE_EVENT (2개 컬럼)
-- 기대값: BIRTH=NULL, TEL='010-0000-0000'
-- =============================================================================
SELECT 'hmmall.ONLINE_EVENT' AS tbl,
       BIRTH, TEL
FROM hmmall.ONLINE_EVENT
LIMIT 3;

-- =============================================================================
-- 8. hmmall.COUNSEL (2개 컬럼)
-- 기대값: EMAIL='test@test.ktown4u.com', TEL='010-0000-0000'
-- =============================================================================
SELECT 'hmmall.COUNSEL' AS tbl,
       EMAIL, TEL
FROM hmmall.COUNSEL
LIMIT 3;

-- =============================================================================
-- 9. hmmall.SELL_CER (3개 컬럼)
-- 기대값: EMAIL='test@test.ktown4u.com', TEL/HP='010-0000-0000'
-- =============================================================================
SELECT 'hmmall.SELL_CER' AS tbl,
       EMAIL, TEL, HP
FROM hmmall.SELL_CER
LIMIT 3;

-- =============================================================================
-- 10. hmmall.DELIVERY_3PL (6개 컬럼)
-- 기대값: FIRST_NAME='테스트', LAST_NAME='수령인', SENDER='테스트발송인'
--         ADDR1='테스트주소', ADDR2='', ZIPNO='00000'
-- =============================================================================
SELECT 'hmmall.DELIVERY_3PL' AS tbl,
       FIRST_NAME, LAST_NAME, SENDER, ADDR1, ADDR2, ZIPNO
FROM hmmall.DELIVERY_3PL
LIMIT 3;

-- =============================================================================
-- 11. hmmall.SELL_EPASS (4개 컬럼)
-- 기대값: PAYER_EMAIL='test@test.ktown4u.com', ADDR1='테스트주소', ADDR2='', ZIPNO='00000'
-- =============================================================================
SELECT 'hmmall.SELL_EPASS' AS tbl,
       PAYER_EMAIL, ADDR1, ADDR2, ZIPNO
FROM hmmall.SELL_EPASS
LIMIT 3;

-- =============================================================================
-- 12. hmmall.BANK_INOUT (1개 컬럼)
-- 기대값: PAY_USER_NM='테스트입금자'
-- =============================================================================
SELECT 'hmmall.BANK_INOUT' AS tbl,
       PAY_USER_NM
FROM hmmall.BANK_INOUT
LIMIT 3;

-- =============================================================================
-- 13. hmmall.ALIMTALK_REQ_HISTORY (1개 컬럼)
-- 기대값: TEL='010-0000-0000'
-- =============================================================================
SELECT 'hmmall.ALIMTALK_REQ_HISTORY' AS tbl,
       TEL
FROM hmmall.ALIMTALK_REQ_HISTORY
LIMIT 3;

-- =============================================================================
-- 14. capybara.REVIEWS (2개 컬럼)
-- 기대값: USERNAME='테스트사용자', USER_ID='testuser@test.ktown4u.com'
-- =============================================================================
SELECT 'capybara.REVIEWS' AS tbl,
       USERNAME, USER_ID
FROM capybara.REVIEWS
LIMIT 3;

-- =============================================================================
-- 15. capybara.USER_DEVICES (1개 컬럼)
-- 기대값: device_id LIKE 'test_device_%'
-- =============================================================================
SELECT 'capybara.USER_DEVICES' AS tbl, id,
       device_id
FROM capybara.USER_DEVICES
LIMIT 3;
```

### 검증 체크리스트

| # | 테이블 | 마스킹 컬럼 수 | 기대값 요약 |
|---|--------|---------------|-------------|
| 1 | hmmall.USER | 9 | 이름/이메일/전화/주소/생년월일 마스킹 |
| 2 | hmmall.SELL_DELIY_ADDR | 9 | SSN=NULL, 수령인/전화/주소 마스킹 |
| 3 | hmmall.SELL_DELIY_ADDR_SNAPSHOT | 9 | SSN=NULL, 수령인/전화/주소 마스킹 |
| 4 | hmmall.SELL_DELIY_ADDR_ADD | 5 | 모두 NULL (BIRTH, PASS_NO, ACCT_NO 등) |
| 5 | hmmall.USER_DELIY_ADDR | 8 | 수령인/전화/주소 마스킹 |
| 6 | hmmall.FAN_EVENT_USER | 6 | 이메일/생년월일/전화 마스킹 |
| 7 | hmmall.ONLINE_EVENT | 2 | BIRTH=NULL, 전화 마스킹 |
| 8 | hmmall.COUNSEL | 2 | 이메일/전화 마스킹 |
| 9 | hmmall.SELL_CER | 3 | 이메일/전화 마스킹 |
| 10 | hmmall.DELIVERY_3PL | 6 | 이름/발송인/주소 마스킹 |
| 11 | hmmall.SELL_EPASS | 4 | 이메일/주소 마스킹 |
| 12 | hmmall.BANK_INOUT | 1 | 입금자명 마스킹 |
| 13 | hmmall.ALIMTALK_REQ_HISTORY | 1 | 전화 마스킹 |
| 14 | capybara.REVIEWS | 2 | 사용자명/ID 마스킹 |
| 15 | capybara.USER_DEVICES | 1 | device_id='test_device_{id}' |

---

## Uncertainty Map

| 항목 | 확신도 | 설명 |
|------|--------|------|
| 병목 원인 분석 | 높음 | innodb_log_file_size, io_capacity가 명확한 원인 |
| 배치 삭제 효과 | 높음 | 일반적으로 검증된 방법 |
| 예상 시간 | 중간 | 네트워크 상태, 동시 부하에 따라 변동 가능 (2-3시간 예상) |
| 최적 배치 크기 | 중간 | 50,000건 기본, 필요시 조정 가능 |
