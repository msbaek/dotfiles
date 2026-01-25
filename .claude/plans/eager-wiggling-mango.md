# Dev DB 개인정보 스크럽(Scrubbing) 계획서

> 작성일: 2026-01-12
> 목적: ISMS-P 인증기준 준수를 위한 개발 DB 개인정보 처리
> 참조: `docs/dev-db-scrubing.md`, `plan-docs/docs/isms-p/private-fields/fields.md`

---

## 1. 배경 및 목적

### 1.1 배경
- ISMS-P 인증기준 '2.8.4 시험 데이터 보안' 및 '3.2.5 가명정보 처리' 요건 충족 필요
- 개발 환경에서 운영 데이터 유출 예방
- 테스트 중 실제 고객에게 문자/이메일 발송 사고 방지

### 1.2 목적
- dev DB의 개인정보를 안전하게 스크럽(익명화/가명처리)
- 재사용 가능한 SQL 스크립트로 정기 반복 실행 지원

---

## 2. 환경 정보

| 항목 | 값 | 비고 |
|------|-----|------|
| DBMS | Aurora RDS MySQL | MySQL 문법 사용 |
| 스키마 | hmmall + capybara | 단일 DB 내 2개 스키마 |
| 암호화 상태 | 평문 저장 | 비밀번호만 단방향 암호화 |
| 작업 방식 | 직접 SQL 실행 | DBeaver/CLI 등 |
| 롤백 전략 | 운영 데이터 재복사 | 백업 불필요 |
| 시간 제약 | 없음 | 언제든 실행 가능 |
| 반복 주기 | 정기 반복 필요 | 운영 DB 동기화 시마다 |

---

## 3. 대상 테이블 및 필드

### 3.1 hmmall 스키마 - 핵심 테이블

#### USER 테이블 (마스터)
| 필드 | 설명 | 처리 방식 | 처리값 |
|------|------|----------|--------|
| USER_NM | 이름 | 고정값 | `테스트이름` |
| EMAIL | 이메일 | 고정값 | `test@test.ktown4u.com` |
| TEL | 전화번호 | 더미값 | `010-0000-0000` |
| HP | 휴대폰 | 더미값 | `010-0000-0000` |
| ZIPNO | 우편번호 | 고정값 | `00000` |
| ADDR1 | 주소1 | 고정값 | `테스트주소` |
| ADDR2 | 주소2 | 고정값 | (빈 문자열) |
| NATI_CITY | 도시 | 고정값 | `테스트도시` |

#### SELL_DELIY_ADDR 테이블 (트랜잭션)
| 필드 | 설명 | 처리 방식 | 처리값 |
|------|------|----------|--------|
| **SSN** | **주민번호** | **NULL** | `NULL` |
| RECIPIENT | 수령인 | 고정값 | `테스트수령인` |
| RECIPIENT2 | 수령인2 | 고정값 | (빈 문자열) |
| TEL | 전화번호 | 더미값 | `010-0000-0000` |
| HP | 휴대폰 | 더미값 | `010-0000-0000` |
| ZIPNO | 우편번호 | 고정값 | `00000` |
| ADDR1 | 주소1 | 고정값 | `테스트주소` |
| ADDR2 | 주소2 | 고정값 | (빈 문자열) |
| NATI_CITY | 도시 | 고정값 | `테스트도시` |

#### SELL_DELIY_ADDR_ADD 테이블 (트랜잭션)
| 필드 | 설명 | 처리 방식 | 처리값 |
|------|------|----------|--------|
| **BIRTH** | **생년월일** | **NULL** | `NULL` |
| **PASS_NO** | **개인통관부호** | **NULL** | `NULL` |
| **ACCT_NO** | **계좌번호** | **NULL** | `NULL` |
| BANK_CD | 은행코드 | NULL | `NULL` |
| ACCT_NM | 예금주명 | NULL | `NULL` |

#### USER_DELIY_ADDR 테이블 (마스터)
| 필드 | 설명 | 처리 방식 | 처리값 |
|------|------|----------|--------|
| RECIPIENT | 수령인 | 고정값 | `테스트수령인` |
| RECIPIENT2 | 수령인2 | 고정값 | (빈 문자열) |
| TEL | 전화번호 | 더미값 | `010-0000-0000` |
| HP | 휴대폰 | 더미값 | `010-0000-0000` |
| ZIPNO | 우편번호 | 고정값 | `00000` |
| ADDR1 | 주소1 | 고정값 | `테스트주소` |
| ADDR2 | 주소2 | 고정값 | (빈 문자열) |
| NATI_CITY | 도시 | 고정값 | `테스트도시` |

#### SELL_DELIY_ADDR_SNAPSHOT 테이블 (스냅샷)
- SELL_DELIY_ADDR와 동일한 구조
- 동일한 UPDATE 쿼리 적용

### 3.2 hmmall 스키마 - 추가 테이블

#### FAN_EVENT_USER 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| EMAIL | 이메일 | `test@test.ktown4u.com` |
| BIRTH | 생년월일 | `NULL` |
| HP | 휴대폰 | `010-0000-0000` |
| TEL | 전화번호 | `010-0000-0000` |
| DELIY_HP | 배송 휴대폰 | `010-0000-0000` |
| DELIY_TEL | 배송 전화번호 | `010-0000-0000` |

#### ONLINE_EVENT 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| BIRTH | 생년월일 | `NULL` |
| TEL | 연락처 | `010-0000-0000` |

#### COUNSEL 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| EMAIL | 이메일 | `test@test.ktown4u.com` |
| TEL | 전화번호 | `010-0000-0000` |

#### SELL_CER 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| EMAIL | 이메일 | `test@test.ktown4u.com` |
| TEL | 전화번호 | `010-0000-0000` |
| HP | 휴대폰 | `010-0000-0000` |

#### DELIVERY_3PL 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| FIRST_NAME | 수신인 명 | `테스트` |
| LAST_NAME | 수신인 성 | `수령인` |
| SENDER | 발신인 성명 | `테스트발송인` |
| ADDR1, ADDR2, ZIPNO | 주소 | 고정값 |

#### SELL_EPASS 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| PAYER_EMAIL | 결제자 이메일 | `test@test.ktown4u.com` |
| ADDR1, ADDR2, ZIPNO | 주소 | 고정값 |

#### BANK_INOUT 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| PAY_USER_NM | 입금자명 | `테스트입금자` |

#### ALIMTALK_REQ_HISTORY 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| TEL | 알림톡 수신 전화번호 | `010-0000-0000` |

### 3.3 gms 스키마 (물류 시스템) - **추가됨**

#### packings 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| consignee | 수신인 | `테스트수령인` |
| email | 이메일 | `test@test.ktown4u.com` |
| phone | 휴대폰 | `010-0000-0000` |
| tel | 전화번호 | `010-0000-0000` |
| address_1 | 상세주소1 | `테스트주소` |
| address_2 | 상세주소2 | (빈 문자열) |
| city | 도시 | `테스트도시` |
| zip_code | 우편번호 | `00000` |

#### shipping_orders 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| user_name | 수취인 | `테스트수령인` |
| recipient_2 | 수취인2 | (빈 문자열) |
| user_email | 이메일 | `test@test.ktown4u.com` |
| user_phone | 휴대폰 | `010-0000-0000` |
| user_tel | 전화번호 | `010-0000-0000` |
| address_1 | 상세주소1 | `테스트주소` |
| address_2 | 상세주소2 | (빈 문자열) |
| city | 군/구 | `테스트도시` |
| state_name | 시/도 | `테스트시` |
| zip_code | 우편번호 | `00000` |
| company_name | 회사명 | `테스트회사` |

#### pick_up_onsites 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| user_id | 사용자 ID | `testuser` |
| user_name | 사용자명 | `테스트사용자` |
| user_phone | 휴대폰 | `010-0000-0000` |

#### companies 테이블 (B2B)
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| owner_name | 대표자 | `테스트대표` |
| keyman_name | 담당자명 | `테스트담당자` |
| keyman_contact | 담당자 연락처 | `010-0000-0000` |
| registration_number | **사업자번호** | `000-00-00000` |

#### centers 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| keyman_name | 담당자 이름 | `테스트담당자` |
| keyman_contact | 담당자 연락처 | `010-0000-0000` |

#### warehouses 테이블
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| keyman_name | 담당자 이름 | `테스트담당자` |
| keyman_contact | 담당자 연락처 | `010-0000-0000` |
| address_1, address_2, city, state_name, zip_code | 주소 | 고정값 |

### 3.4 capybara 스키마

#### REVIEWS 테이블 (트랜잭션)
| 필드 | 설명 | 처리 방식 | 처리값 |
|------|------|----------|--------|
| USERNAME | 사용자명 | 고정값 | `테스트사용자` |
| USER_ID | 사용자ID | 고정값 | `testuser@test.ktown4u.com` |

#### USER_DEVICES 테이블 (추가됨)
| 필드 | 설명 | 처리 방식 |
|------|------|----------|
| device_id | 디바이스 고유 ID | `NULL` 또는 고정값 |

#### V_USERS (View)
- hmmall.USER 테이블의 View
- 원본 테이블 처리 시 자동 반영 (별도 처리 불필요)

### 3.5 스크럽 제외 스키마

#### catalog 스키마
- **개인정보 없음** (상품/재고 관리 전용)
- CREATED_BY, LAST_MODIFIED_BY만 존재 (작업자 ID, 처리 불필요)

#### thomas 스키마
- hmmall 테이블을 참조하므로 별도 처리 불필요

---

## 4. 처리 원칙

### 4.1 ISMS-P 기준 처리 방식
| 필드 구분 | 처리 방법 | 이유 |
|-----------|-----------|------|
| 주민번호/SSN | **NULL 처리** | 법적 리스크 원천 차단 |
| 이름 | 고정값 | 로직 검증에 충분한 식별성만 유지 |
| 전화번호 | **더미값 통일** | 테스트 중 실제 문자 발송 사고 차단 |
| 이메일 | **고정값+내부도메인** | 테스트 중 실제 메일 발송 사고 차단 |
| 주소 | 고정값 | 배송 테스트용 형식만 유지 |
| 계좌번호/통관부호 | **NULL 처리** | 금융/개인 정보 유출 방지 |

### 4.2 user_no 등 조인 키
- **처리하지 않음**: 사람이 식별할 수 없는 시퀀스 키값
- 테이블 간 조인 관계 유지

---

## 5. 실행 계획

### Phase 1: 데이터 분석 (필수)

**목적**: 테이블별 건수 파악 → 삭제 여부 결정

```sql
-- 테이블별 건수 조회
SELECT 'USER' AS tbl, COUNT(*) AS cnt FROM hmmall.USER
UNION ALL SELECT 'SELL_DELIY_ADDR', COUNT(*) FROM hmmall.SELL_DELIY_ADDR
UNION ALL SELECT 'SELL_DELIY_ADDR_ADD', COUNT(*) FROM hmmall.SELL_DELIY_ADDR_ADD
UNION ALL SELECT 'USER_DELIY_ADDR', COUNT(*) FROM hmmall.USER_DELIY_ADDR
UNION ALL SELECT 'REVIEWS', COUNT(*) FROM capybara.REVIEWS;

-- 날짜별 분포 확인 (삭제 대상 판단용)
-- 주의: 실제 날짜 컬럼명 확인 필요 (REG_DT, CREATED_AT 등)
SELECT
    CASE WHEN REG_DT < '2025-01-01' THEN '2025 이전' ELSE '2025 이후' END AS period,
    COUNT(*) AS cnt
FROM hmmall.SELL_DELIY_ADDR
GROUP BY 1;
```

### Phase 2: 이전 데이터 삭제 (선택적)

**조건**: Phase 1 분석 결과 데이터 양이 많아 UPDATE 성능에 영향이 있을 때만 실행

**삭제 대상**:
- 트랜잭션 테이블만 (SELL_DELIY_ADDR, SELL_DELIY_ADDR_ADD, REVIEWS)
- **마스터 테이블(USER, USER_DELIY_ADDR)은 삭제 불가**

**삭제 순서** (FK 제약 고려):
1. SELL_DELIY_ADDR_ADD (자식)
2. SELL_DELIY_ADDR (부모)
3. REVIEWS

```sql
-- 삭제 전 건수 확인
SELECT '삭제 예정: SELL_DELIY_ADDR' AS info, COUNT(*) AS cnt
FROM hmmall.SELL_DELIY_ADDR WHERE REG_DT < '2025-01-01';

-- Step 1: 자식 테이블 먼저 삭제
DELETE sda FROM hmmall.SELL_DELIY_ADDR_ADD sda
INNER JOIN hmmall.SELL_DELIY_ADDR sd ON sda.DELIY_ADDR_NO = sd.DELIY_ADDR_NO
WHERE sd.REG_DT < '2025-01-01';

-- Step 2: 부모 테이블 삭제
DELETE FROM hmmall.SELL_DELIY_ADDR WHERE REG_DT < '2025-01-01';

-- Step 3: REVIEWS 삭제
DELETE FROM capybara.REVIEWS WHERE CREATED_AT < '2025-01-01';
```

### Phase 3: 스크럽 쿼리 실행

#### 3-A. hmmall 핵심 테이블
```sql
-- 3-1. hmmall.USER
UPDATE hmmall.USER SET
    USER_NM = '테스트이름', EMAIL = 'test@test.ktown4u.com',
    TEL = '010-0000-0000', HP = '010-0000-0000',
    ZIPNO = '00000', ADDR1 = '테스트주소', ADDR2 = '', NATI_CITY = '테스트도시';

-- 3-2. hmmall.SELL_DELIY_ADDR
UPDATE hmmall.SELL_DELIY_ADDR SET
    SSN = NULL, RECIPIENT = '테스트수령인', RECIPIENT2 = '',
    TEL = '010-0000-0000', HP = '010-0000-0000',
    ZIPNO = '00000', ADDR1 = '테스트주소', ADDR2 = '', NATI_CITY = '테스트도시';

-- 3-3. hmmall.SELL_DELIY_ADDR_SNAPSHOT (스냅샷)
UPDATE hmmall.SELL_DELIY_ADDR_SNAPSHOT SET
    SSN = NULL, RECIPIENT = '테스트수령인', RECIPIENT2 = '',
    TEL = '010-0000-0000', HP = '010-0000-0000',
    ZIPNO = '00000', ADDR1 = '테스트주소', ADDR2 = '', NATI_CITY = '테스트도시';

-- 3-4. hmmall.SELL_DELIY_ADDR_ADD
UPDATE hmmall.SELL_DELIY_ADDR_ADD SET
    BIRTH = NULL, PASS_NO = NULL, ACCT_NO = NULL, BANK_CD = NULL, ACCT_NM = NULL;

-- 3-5. hmmall.USER_DELIY_ADDR
UPDATE hmmall.USER_DELIY_ADDR SET
    RECIPIENT = '테스트수령인', RECIPIENT2 = '',
    TEL = '010-0000-0000', HP = '010-0000-0000',
    ZIPNO = '00000', ADDR1 = '테스트주소', ADDR2 = '', NATI_CITY = '테스트도시';
```

#### 3-B. hmmall 추가 테이블
```sql
-- 3-6. hmmall.FAN_EVENT_USER
UPDATE hmmall.FAN_EVENT_USER SET
    EMAIL = 'test@test.ktown4u.com', BIRTH = NULL,
    HP = '010-0000-0000', TEL = '010-0000-0000',
    DELIY_HP = '010-0000-0000', DELIY_TEL = '010-0000-0000';

-- 3-7. hmmall.ONLINE_EVENT
UPDATE hmmall.ONLINE_EVENT SET BIRTH = NULL, TEL = '010-0000-0000';

-- 3-8. hmmall.COUNSEL
UPDATE hmmall.COUNSEL SET EMAIL = 'test@test.ktown4u.com', TEL = '010-0000-0000';

-- 3-9. hmmall.SELL_CER
UPDATE hmmall.SELL_CER SET
    EMAIL = 'test@test.ktown4u.com', TEL = '010-0000-0000', HP = '010-0000-0000';

-- 3-10. hmmall.DELIVERY_3PL
UPDATE hmmall.DELIVERY_3PL SET
    FIRST_NAME = '테스트', LAST_NAME = '수령인', SENDER = '테스트발송인',
    ADDR1 = '테스트주소', ADDR2 = '', ZIPNO = '00000';

-- 3-11. hmmall.SELL_EPASS
UPDATE hmmall.SELL_EPASS SET
    PAYER_EMAIL = 'test@test.ktown4u.com',
    ADDR1 = '테스트주소', ADDR2 = '', ZIPNO = '00000';

-- 3-12. hmmall.BANK_INOUT
UPDATE hmmall.BANK_INOUT SET PAY_USER_NM = '테스트입금자';

-- 3-13. hmmall.ALIMTALK_REQ_HISTORY
UPDATE hmmall.ALIMTALK_REQ_HISTORY SET TEL = '010-0000-0000';
```

#### 3-C. gms 스키마 (물류 시스템)
```sql
-- 3-14. gms.packings
UPDATE gms.packings SET
    consignee = '테스트수령인', email = 'test@test.ktown4u.com',
    phone = '010-0000-0000', tel = '010-0000-0000',
    address_1 = '테스트주소', address_2 = '', city = '테스트도시', zip_code = '00000';

-- 3-15. gms.shipping_orders
UPDATE gms.shipping_orders SET
    user_name = '테스트수령인', recipient_2 = '',
    user_email = 'test@test.ktown4u.com',
    user_phone = '010-0000-0000', user_tel = '010-0000-0000',
    address_1 = '테스트주소', address_2 = '',
    city = '테스트도시', state_name = '테스트시', zip_code = '00000',
    company_name = '테스트회사';

-- 3-16. gms.pick_up_onsites
UPDATE gms.pick_up_onsites SET
    user_id = 'testuser', user_name = '테스트사용자', user_phone = '010-0000-0000';

-- 3-17. gms.companies (B2B)
UPDATE gms.companies SET
    owner_name = '테스트대표', keyman_name = '테스트담당자',
    keyman_contact = '010-0000-0000', registration_number = '000-00-00000';

-- 3-18. gms.centers
UPDATE gms.centers SET keyman_name = '테스트담당자', keyman_contact = '010-0000-0000';

-- 3-19. gms.warehouses
UPDATE gms.warehouses SET
    keyman_name = '테스트담당자', keyman_contact = '010-0000-0000',
    address_1 = '테스트주소', address_2 = '',
    city = '테스트도시', state_name = '테스트시', zip_code = '00000';
```

#### 3-D. capybara 스키마
```sql
-- 3-20. capybara.REVIEWS
UPDATE capybara.REVIEWS SET
    USERNAME = '테스트사용자', USER_ID = 'testuser@test.ktown4u.com';

-- 3-21. capybara.USER_DEVICES (선택적)
UPDATE capybara.USER_DEVICES SET device_id = 'test_device_id';
```

### Phase 4: 검증

```sql
-- =============================================================================
-- 핵심 필드 검증 (모든 결과가 0이어야 정상)
-- =============================================================================

-- hmmall 핵심 테이블
SELECT 'hmmall.USER.USER_NM' AS field, COUNT(*) AS unprocessed
FROM hmmall.USER WHERE USER_NM IS NOT NULL AND USER_NM != '테스트이름'
UNION ALL SELECT 'hmmall.USER.EMAIL', COUNT(*)
FROM hmmall.USER WHERE EMAIL IS NOT NULL AND EMAIL != 'test@test.ktown4u.com'
UNION ALL SELECT 'hmmall.SELL_DELIY_ADDR.SSN', COUNT(*)
FROM hmmall.SELL_DELIY_ADDR WHERE SSN IS NOT NULL
UNION ALL SELECT 'hmmall.SELL_DELIY_ADDR_ADD.PASS_NO', COUNT(*)
FROM hmmall.SELL_DELIY_ADDR_ADD WHERE PASS_NO IS NOT NULL
UNION ALL SELECT 'hmmall.SELL_DELIY_ADDR_ADD.ACCT_NO', COUNT(*)
FROM hmmall.SELL_DELIY_ADDR_ADD WHERE ACCT_NO IS NOT NULL

-- gms 테이블
UNION ALL SELECT 'gms.packings.email', COUNT(*)
FROM gms.packings WHERE email IS NOT NULL AND email != 'test@test.ktown4u.com'
UNION ALL SELECT 'gms.shipping_orders.user_email', COUNT(*)
FROM gms.shipping_orders WHERE user_email IS NOT NULL AND user_email != 'test@test.ktown4u.com'
UNION ALL SELECT 'gms.companies.registration_number', COUNT(*)
FROM gms.companies WHERE registration_number IS NOT NULL AND registration_number != '000-00-00000'

-- capybara 테이블
UNION ALL SELECT 'capybara.REVIEWS.USERNAME', COUNT(*)
FROM capybara.REVIEWS WHERE USERNAME IS NOT NULL AND USERNAME != '테스트사용자';

-- =============================================================================
-- 샘플 데이터 육안 확인
-- =============================================================================
SELECT 'hmmall.USER' AS tbl, USER_NO, USER_NM, EMAIL, TEL FROM hmmall.USER LIMIT 3;
SELECT 'hmmall.SELL_DELIY_ADDR' AS tbl, SSN, RECIPIENT, TEL FROM hmmall.SELL_DELIY_ADDR LIMIT 3;
SELECT 'gms.packings' AS tbl, consignee, email, phone FROM gms.packings LIMIT 3;
SELECT 'gms.shipping_orders' AS tbl, user_name, user_email FROM gms.shipping_orders LIMIT 3;
```

---

## 6. 산출물 구조 (생성 예정)

```
scripts/db-scrubbing/
├── README.md                    # 실행 가이드
├── 00_analyze.sql               # Phase 1: 데이터 분석
├── 01_delete_old_data.sql       # Phase 2: 선택적 삭제
├── 02_scrub_hmmall_core.sql     # Phase 3-A: hmmall 핵심 테이블
├── 03_scrub_hmmall_extra.sql    # Phase 3-B: hmmall 추가 테이블
├── 04_scrub_gms.sql             # Phase 3-C: gms 스키마
├── 05_scrub_capybara.sql        # Phase 3-D: capybara 스키마
├── 06_verify.sql                # Phase 4: 검증
└── run_scrubbing.sh             # 전체 실행 + 로그 기록
```

### 스크립트 실행 순서
1. `00_analyze.sql` - 건수 파악
2. (선택) `01_delete_old_data.sql` - 2025/01/01 이전 데이터 삭제
3. `02_scrub_hmmall_core.sql` - 핵심 테이블 우선 처리
4. `03_scrub_hmmall_extra.sql` - 추가 테이블 처리
5. `04_scrub_gms.sql` - 물류 시스템 처리
6. `05_scrub_capybara.sql` - 리뷰 시스템 처리
7. `06_verify.sql` - 검증

---

## 7. 감사 로그 요건

**기록 내용**:
- 실행 일시
- 실행한 쿼리 목록
- 각 쿼리별 처리 건수

**로그 파일**: `logs/scrubbing_YYYYMMDD_HHMMSS.log`

---

## 8. 실행 전 확인사항

| 항목 | 확인 방법 | 상태 |
|------|----------|------|
| 날짜 컬럼명 확인 | `DESCRIBE hmmall.SELL_DELIY_ADDR;` | 미확인 |
| FK 관계 확인 | `SHOW CREATE TABLE hmmall.SELL_DELIY_ADDR_ADD;` | 미확인 |
| 추가 개인정보 테이블 | information_schema 조회 | 미확인 |

---

## 9. Uncertainty Map

| 항목 | 확신도 | 해결 방법 |
|------|--------|----------|
| 날짜 컬럼명 (REG_DT, CREATED_AT 등) | 낮음 | 실행 전 DESCRIBE로 확인 |
| SELL_DELIY_ADDR ↔ SELL_DELIY_ADDR_ADD FK 관계 | 중간 | SHOW CREATE TABLE로 확인 |
| gms 스키마 컬럼명 (snake_case vs camelCase) | 중간 | DESCRIBE로 확인 |
| 대용량 테이블 UPDATE 성능 | 중간 | Phase 1 분석 후 배치 처리 검토 |
| hmmall 추가 테이블 존재 여부 | 낮음 | information_schema 검색 |

---

## 10. 테이블 통계 요약

| 스키마 | 테이블 수 | 주요 대상 |
|--------|----------|----------|
| hmmall | 13+ | USER, SELL_DELIY_ADDR, SELL_DELIY_ADDR_ADD, USER_DELIY_ADDR, FAN_EVENT_USER 등 |
| gms | 6 | packings, shipping_orders, pick_up_onsites, companies, centers, warehouses |
| capybara | 2 | REVIEWS, USER_DEVICES |
| **합계** | **21+** | |

---

## 11. 다음 단계

### 필수
1. [ ] Phase 1 분석 쿼리 실행 → 테이블별 건수 확인
2. [ ] 실제 컬럼명/FK 관계 확인 (DESCRIBE 쿼리)
3. [ ] 삭제 여부 결정 (건수 기반)

### 구현
4. [ ] SQL 스크립트 파일 생성 (6개 파일)
5. [ ] run_scrubbing.sh 쉘 스크립트 생성
6. [ ] 스크럽 실행 및 검증
7. [ ] 감사 로그 확인

---

## 12. 참조 문서

- `docs/dev-db-scrubing.md` - ISMS-P 기준 및 필드별 처리 원칙
- `plan-docs/docs/isms-p/private-fields/fields.md` - 개인정보 필드 목록
- `plan-docs/docs/isms-p/private-fields/gms.md` - gms 스키마 상세
- `plan-docs/docs/isms-p/private-fields/capybara.md` - capybara 스키마 상세
- `plan-docs/docs/isms-p/private-fields/ktown4u-java.md` - hmmall 스키마 상세
- `plan-docs/docs/isms-p/private-fields/개인정보_필드_조사_결과.md` - 전체 조사 결과
