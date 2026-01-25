# 증분 난독화(Incremental Scrubbing) 구현 계획

## 목표

기존 전체 난독화 스크립트에 **증분 난독화 기능**을 추가하여:
1. 초기: 전체 데이터 난독화 (기존 동작 유지)
2. 정기 실행: 특정 일자 이후 데이터만 난독화
3. 테스트 후 정리: 테스트 시작일 이후 생성된 데이터만 난독화

---

## 구현 방식: SQL 템플릿 + 플레이스홀더 치환

### 핵심 아이디어
- SQL 파일에 `/* @WHERE_테이블명 */` 플레이스홀더 삽입
- `run_scrubbing.sh`에서 `--from-date` 옵션 파싱 후 `sed`로 치환
- 증분 모드가 아니면 플레이스홀더를 빈 문자열로 치환 (기존 동작 유지)

---

## 수정 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `scripts/db-scrubbing/run_scrubbing.sh` | `--from-date=YYYY-MM-DD` 옵션 추가, 템플릿 처리 함수 |
| `scripts/db-scrubbing/02_scrub_hmmall_core.sql` | 플레이스홀더 추가 |
| `scripts/db-scrubbing/03_scrub_hmmall_extra.sql` | 플레이스홀더 추가 |
| `scripts/db-scrubbing/04_scrub_capybara.sql` | 플레이스홀더 추가 |
| `scripts/db-scrubbing/05_verify.sql` | 증분 검증 쿼리 추가 |
| `docs/DB-SCRUBBING-PLAN.md` | 새 옵션 및 시나리오 문서화 |

---

## 구현 순서 및 진행 상황

- [ ] **1단계**: run_scrubbing.sh 옵션 파싱 확장 - `--from-date` 옵션 추가
- [ ] **2단계**: process_sql_template() 함수 구현 - sed 치환 로직
- [ ] **3단계**: 02_scrub_hmmall_core.sql 플레이스홀더 추가
- [ ] **4단계**: 03_scrub_hmmall_extra.sql 플레이스홀더 추가
- [ ] **5단계**: 04_scrub_capybara.sql 플레이스홀더 추가
- [ ] **6단계**: 05_verify.sql 증분 검증 추가
- [ ] **7단계**: README.md 문서 업데이트

---

## 상세 구현

### 1. run_scrubbing.sh 수정

```bash
# 새 옵션 추가
--from-date=YYYY-MM-DD    # 이 날짜 이후 데이터만 난독화

# 핵심 함수: SQL 템플릿 처리
process_sql_template() {
    local sql_file=$1
    local temp_file="/tmp/scrubbing_$(basename $sql_file)"

    if [ -n "$FROM_DATE" ]; then
        # 증분 모드: 플레이스홀더를 WHERE 조건으로 치환
        sed -e "s|/\* @WHERE_SELL_DELIY_ADDR \*/|WHERE REG_DT >= '$FROM_DATE'|g" \
            -e "s|/\* @WHERE_REVIEWS \*/|WHERE CREATED_AT >= '$FROM_DATE'|g" \
            ...
    else
        # 전체 모드: 플레이스홀더 제거
        sed -e "s|/\* @WHERE_[A-Z_]* \*/||g" ...
    fi
}
```

### 2. SQL 파일 플레이스홀더 예시

**02_scrub_hmmall_core.sql:**
```sql
-- 트랜잭션 테이블: 증분 필터 가능
UPDATE hmmall.SELL_DELIY_ADDR SET
    SSN = NULL, RECIPIENT = '테스트수령인', ...
/* @WHERE_SELL_DELIY_ADDR */;

-- JOIN이 필요한 테이블
UPDATE hmmall.SELL_DELIY_ADDR_ADD sda
/* @JOIN_SELL_DELIY_ADDR_FOR_ADD */
SET sda.BIRTH = NULL, ...
/* @WHERE_SELL_DELIY_ADDR_ADD */;

-- 마스터 테이블: 항상 전체 처리 (증분 모드에서도)
UPDATE hmmall.USER SET USER_NM = '테스트이름', ...;
```

### 3. 테이블별 증분 처리 전략

| 테이블 | 날짜 컬럼 | 증분 전략 |
|--------|----------|----------|
| SELL_DELIY_ADDR | `REG_DT` | `WHERE REG_DT >= :from_date` |
| SELL_DELIY_ADDR_ADD | 없음 | JOIN으로 부모 테이블 날짜 필터 |
| REVIEWS | `CREATED_AT` | `WHERE CREATED_AT >= :from_date` |
| USER, USER_DELIY_ADDR | 마스터 | **항상 전체 처리** (건수 적음) |

---

## 실행 시나리오

### A. 초기 전체 난독화
```bash
./run_scrubbing.sh                    # 기존 동작
./run_scrubbing.sh --skip-delete      # 삭제 없이
```

### B. 정기 증분 난독화
```bash
./run_scrubbing.sh --from-date=2026-01-10 --skip-delete
```

### C. 테스트 후 정리
```bash
./run_scrubbing.sh --from-date=2026-01-13 --skip-delete
```

---

## 검증 방법

1. `--dry-run` 모드로 생성된 SQL 확인
2. 증분 모드에서 플레이스홀더가 올바르게 치환되는지 확인
3. 실제 dev DB에서 테스트 실행 후 05_verify.sql로 검증

---

## Uncertainty Map

| 항목 | 확신도 | 비고 |
|------|--------|------|
| SELL_DELIY_ADDR.REG_DT | 높음 | 이미 삭제 스크립트에서 사용 중 |
| REVIEWS.CREATED_AT | 높음 | 이미 삭제 스크립트에서 사용 중 |
| USER 등 마스터 테이블 날짜 컬럼 | 낮음 | 스키마 조회 필요 (없으면 전체 처리) |
| sed 치환 안정성 | 중간 | dry-run 테스트로 검증 |
