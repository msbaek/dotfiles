# Plan: DB 스크럽 변경사항 테스트 및 검증

## 현재 상태 분석

### 완료된 작업 ✅
| 항목 | 상태 | 비고 |
|------|------|------|
| `02_scrub_hmmall_core.sql` - USER.BIRTH_DT 추가 | ✅ | e0cace9 커밋 |
| `05_verify.sql` - BIRTH_DT 검증 쿼리 추가 | ✅ | d1b3bcc 커밋 |
| `dev-db-scrubbing-implementation-plan.md` 문서 동기화 | ✅ | d1b3bcc 커밋 |
| Export 완료 (15개 테이블, 총 ~1GB) | ✅ | 2026-01-19 13:40 |
| 로컬 Docker DB 실행 중 | ✅ | Up 3 days |
| 로컬 DB 데이터 Import | ✅ | USER 10K, SELL_DELIY_ADDR 50K 등 |
| 로컬 DB 스크럽 실행 | ✅ | BIRTH_DT='1900-01-01' 확인됨 |

### 남은 작업 ❌
| 항목 | 상태 | 비고 |
|------|------|------|
| 로컬 DB 검증 (05_verify.sql 실행) | ❌ | 새 검증 쿼리 적용 확인 필요 |
| 서버 (Aurora RDS) 스크럽 실행 | ❌ | 실제 운영 데이터 처리 |

---

## 실행 계획

### Phase 1: 로컬 DB 검증 (5분)

**목적:** 새로 추가된 `USER.BIRTH_DT` 검증 쿼리가 정상 작동하는지 확인

```bash
cd /Users/msbaek/git/kt4u/ktown4u-masking/scripts/db-scrubbing

# 검증 쿼리 실행 (모든 결과가 0이어야 정상)
mysql -h 127.0.0.1 -P 3307 -u root -prootpassword < 05_verify.sql
```

**예상 결과:**
- 모든 필드의 `unprocessed` 값이 0
- 특히 `hmmall.USER.BIRTH_DT`가 0인지 확인

---

### Phase 2: 서버 (Aurora RDS) 스크럽 실행

#### 2-1. 사전 준비
```bash
# 1. VPN 연결 확인
nc -zv dev-20260119.cn1xjryhj9xq.ap-northeast-2.rds.amazonaws.com 3306

# 2. AWS SSO 로그인
aws sso login --profile default
```

#### 2-2. 데이터 분석 (Phase 1)
```bash
# 현재 데이터 규모 파악
mysql -h <RDS_ENDPOINT> -u <USER> -p < 00_analyze.sql
```

#### 2-3. 스크럽 실행 옵션

| 옵션 | 설명 | 소요 시간 | 권장 상황 |
|------|------|----------|----------|
| 전체 스크럽 | 모든 데이터 마스킹 | 5~10분 | 최초 실행 |
| 전체 + 삭제 | 2025년 이전 삭제 후 마스킹 | 8~16분 | 데이터 정리 필요 시 |
| 증분 모드 | 특정 날짜 이후만 마스킹 | 1~3분 | 정기 실행 |

**선택된 실행 방법: 전체 스크럽 (삭제 없이)**
```bash
./run_scrubbing.sh --skip-delete
```
- 모든 개인정보 필드 마스킹
- 2025년 이전 데이터 유지 (삭제 안함)
- 예상 소요 시간: 5~10분

#### 2-4. 검증
```bash
# 스크럽 결과 확인
mysql -h <RDS_ENDPOINT> -u <USER> -p < 05_verify.sql
```

---

## 주의사항

### 서버 스크럽 시 확인 필요
1. **VPN 연결 필수** - Aurora RDS 접근용
2. **AWS IAM 인증** - RDS 접속 시 토큰 필요
3. **롤백 방법** - 운영 데이터 재복사 (스냅샷 복구는 시간 소요)
4. **USER 테이블** - 마스터 테이블이므로 삭제되지 않고 전체 UPDATE만 됨

### 증분 모드 특성
- `--from-date` 옵션 사용 시에도 USER, USER_DELIY_ADDR는 **항상 전체 처리**
- 트랜잭션 테이블(SELL_DELIY_ADDR 등)만 날짜 필터 적용

---

## 검증 체크리스트

### 로컬 DB 검증
- [ ] `05_verify.sql` 실행 - 모든 결과 0
- [ ] USER.BIRTH_DT = '1900-01-01' 확인
- [ ] 샘플 데이터 육안 확인

### 서버 DB 검증
- [ ] `05_verify.sql` 실행 - 모든 결과 0
- [ ] 로그 파일 확인 (`logs/scrubbing_*.log`)
- [ ] 처리 건수 확인

---

## 파일 위치

| 파일 | 경로 |
|------|------|
| 스크럽 스크립트 | `scripts/db-scrubbing/` |
| 검증 쿼리 | `scripts/db-scrubbing/05_verify.sql` |
| 실행 로그 | `scripts/db-scrubbing/logs/` |
| 문서 | `docs/dev-db-scrubbing-implementation-plan.md` |

---

## Uncertainty Map

| 항목 | 확신도 | 비고 |
|------|--------|------|
| 로컬 검증 절차 | 높음 | 이미 스크럽 완료 상태, 검증만 필요 |
| 서버 접근 방법 | 중간 | VPN + AWS IAM 인증 필요, 현재 연결 상태 미확인 |
| 증분 모드 동작 | 중간 | 플레이스홀더 치환 로직 테스트 필요 |
| 삭제 옵션 필요 여부 | 낮음 | 사용자 결정 필요 |
