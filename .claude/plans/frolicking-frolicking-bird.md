# 선수금 자료 TxID 누락 원인 조사 계획

## 문제 상황
- BO의 페이먼트 히스토리(`PAYMENT_HISTORY` 테이블)에는 txid가 등록되어 있음
- 선수금 자료(103_선수금자료.xlsx)에서는 TxID가 공란으로 추출됨
- 운영팀에서 원인 확인 요청

## 분석 결과

### 핵심 발견: 데이터 출처 불일치

| 구분 | 테이블 | 비고 |
|-----|--------|-----|
| BO 페이먼트 히스토리 | `PAYMENT_HISTORY` | txid 있음 |
| 선수금 쿼리 (settlement-06.sql) | `SELL_DELIY_ADDR_ADD` | txid 누락 가능 |

**→ 두 테이블이 다름! 이것이 근본 원인일 가능성 높음**

### 선수금 자료 생성 로직 (settlement-06.sql)

**TRANS_ID 출처**: `SELL_DELIY_ADDR_ADD` 테이블
```sql
left outer join hmmall.SELL_DELIY_ADDR_ADD SA
    on SA.SELL_DADDR_NO = DA.SELL_DADDR_NO
-- ...
, SA.TRANS_ID  -- 라인 85, 197
```

**문제 가능성 1: 테이블 불일치 (가장 유력)**
- BO 페이먼트 히스토리: `PAYMENT_HISTORY` 테이블
- 선수금 쿼리: `SELL_DELIY_ADDR_ADD` 테이블
- `PAYMENT_HISTORY`에는 있지만 `SELL_DELIY_ADDR_ADD`에는 없는 TRANS_ID

**문제 가능성 2: LEFT OUTER JOIN**
- `SELL_DELIY_ADDR_ADD` 테이블에 해당 배송 레코드가 없으면 TRANS_ID가 NULL

**문제 가능성 3: GROUP BY로 인한 비결정적 선택**
```sql
group by SE.SELL_NO  -- 주문 단위 그룹화 (선수금 매출)
group by REF_NO      -- 환불 번호 그룹화 (선수금 환불)
```
- 한 주문에 여러 배송이 있을 경우, 어떤 배송의 TRANS_ID가 선택될지 불확실
- MySQL/MariaDB의 비결정적 동작으로 NULL인 TRANS_ID가 선택될 수 있음

---

## 조사 계획

### 1단계: 문제 데이터 샘플 확인
엑셀에서 TxID가 비어있는 행의 배송ID(SELL_DADDR_ID) 추출

**대상 데이터** (스크린샷 기준):
- 행 21: `20251217001640000250` (TxID 빈칸)
- 행 22: `20251217001640000262` (TxID 빈칸)

### 2단계: DB에서 해당 데이터 조회

```sql
-- 2.1 선수금 테이블에서 해당 데이터 확인
SELECT SELL_DADDR_ID, TRANS_ID, KIND, PAYMENT_CD
FROM report.SALES_PREORDER_2025_12
WHERE SELL_DADDR_ID IN ('20251217001640000250', '20251217001640000262');

-- 2.2 SELL_DELIY_ADDR_ADD 테이블에서 TRANS_ID 존재 여부 확인 (현재 쿼리 출처)
SELECT SA.SELL_DADDR_NO, SA.TRANS_ID, DA.SELL_DADDR_ID
FROM hmmall.SELL_DELIY_ADDR DA
LEFT JOIN hmmall.SELL_DELIY_ADDR_ADD SA
    ON SA.SELL_DADDR_NO = DA.SELL_DADDR_NO
WHERE DA.SELL_DADDR_ID IN ('20251217001640000250', '20251217001640000262');

-- 2.3 PAYMENT_HISTORY 테이블에서 TRANS_ID 확인 (BO 페이먼트 히스토리)
SELECT *
FROM hmmall.PAYMENT_HISTORY
WHERE SELL_DADDR_ID IN ('20251217001640000250', '20251217001640000262')
   OR SELL_DADDR_NO IN (
       SELECT SELL_DADDR_NO FROM hmmall.SELL_DELIY_ADDR
       WHERE SELL_DADDR_ID IN ('20251217001640000250', '20251217001640000262')
   );
```

### 3단계: PAYMENT_HISTORY 테이블 구조 확인

```sql
-- PAYMENT_HISTORY 테이블 스키마 확인
DESCRIBE hmmall.PAYMENT_HISTORY;

-- SELL_DELIY_ADDR와의 연결 키 확인
SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'hmmall'
  AND TABLE_NAME = 'PAYMENT_HISTORY';
```

### 4단계: 원인 규명

조사 결과에 따라:

| 시나리오 | 원인 | 해결방안 |
|---------|------|---------|
| **A (가장 유력)** | `PAYMENT_HISTORY`와 `SELL_DELIY_ADDR_ADD` 테이블 불일치 | `PAYMENT_HISTORY`에서 TRANS_ID 조회하도록 쿼리 수정 |
| B | `SELL_DELIY_ADDR_ADD`에 레코드 없음 | JOIN 대상 테이블을 `PAYMENT_HISTORY`로 변경 |
| C | `SELL_DELIY_ADDR_ADD.TRANS_ID`가 NULL | `PAYMENT_HISTORY` 테이블에서 가져오도록 수정 |
| D | GROUP BY로 인한 비결정적 선택 | MAX() 또는 서브쿼리로 명확한 선택 |

### 5단계: 쿼리 수정 제안

**PAYMENT_HISTORY 테이블에서 TRANS_ID 조회 (권장)**:
```sql
-- settlement-06.sql 수정안
-- 기존: left outer join hmmall.SELL_DELIY_ADDR_ADD SA on SA.SELL_DADDR_NO = DA.SELL_DADDR_NO
-- 변경: PAYMENT_HISTORY 테이블 조인 추가

left outer join hmmall.PAYMENT_HISTORY PH
    on PH.SELL_DADDR_NO = DA.SELL_DADDR_NO  -- 또는 적절한 조인 키
-- ...
, COALESCE(PH.TRANS_ID, SA.TRANS_ID) as TRANS_ID  -- PAYMENT_HISTORY 우선
```

**GROUP BY 문제 해결 (보조)**:
```sql
-- MAX() 사용으로 비결정적 선택 방지
, MAX(COALESCE(PH.TRANS_ID, SA.TRANS_ID)) as TRANS_ID
```

---

## 검증 방법

1. **샘플 데이터 검증**: 문제 있는 배송ID로 각 테이블 조회
   - `SELL_DELIY_ADDR_ADD.TRANS_ID` 확인
   - `PAYMENT_HISTORY.TRANS_ID` 확인
   - 두 테이블의 데이터 차이 비교

2. **원인 확정**: TRANS_ID가 어느 테이블에 존재하는지 확인
   - `PAYMENT_HISTORY`에만 있음 → 쿼리 수정 필요
   - 둘 다 없음 → 데이터 입력 프로세스 점검 필요

3. **쿼리 수정 후 재검증**: 수정된 쿼리로 동일 데이터 재추출하여 TRANS_ID 포함 여부 확인

---

## 실행 순서 요약

| 순서 | 작업 | 파일/테이블 |
|-----|------|------------|
| 1 | PAYMENT_HISTORY 테이블 구조 확인 | `hmmall.PAYMENT_HISTORY` |
| 2 | 샘플 데이터로 두 테이블 비교 조회 | `SELL_DELIY_ADDR_ADD`, `PAYMENT_HISTORY` |
| 3 | 원인 확정 및 해결방안 결정 | - |
| 4 | settlement-06.sql 쿼리 수정 | `settlement-06.sql` |
| 5 | 수정된 쿼리로 재추출 및 검증 | `settlement-08.sql` (103.sql) |

---

## 수정 대상 파일

- `settlement-06.sql`: 라인 102-103 (선수금 매출), 라인 216-217 (선수금 환불)
  - `SELL_DELIY_ADDR_ADD` 대신 또는 추가로 `PAYMENT_HISTORY` 조인
