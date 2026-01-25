# AWS Aurora RDS → Local Docker DB 데이터 이관 계획

## 개요

AWS Aurora MySQL (dev-20260115-cluster)에서 db-scrubbing 스크립트에서 사용하는 테이블 데이터를 추출하여 로컬 OrbStack Docker의 MySQL로 로딩하는 계획입니다.

### 결정 사항
- **데이터 범위**: 샘플 데이터 (각 테이블당 최근 1만~10만건)
- **접근 방식**: VPN 연결

## Aurora RDS 정보

| 항목 | 값 |
|------|-----|
| Cluster | dev-20260115-cluster |
| Engine | Aurora MySQL |
| Instance | db.r7g.large |
| Region | ap-northeast-2 |
| Writer Endpoint | dev-20260115.cluster-cn1qryhj0wq.ap-northeast-2.rds.amazonaws.com:3306 |
| Reader Endpoint | dev-20260115.cluster-ro-cn1qryhj0wq.ap-northeast-2.rds.amazonaws.com:3306 |

## 대상 테이블 (총 15개)

### hmmall 스키마 (13개)
| 테이블 | 예상 건수 | 비고 |
|--------|----------|------|
| USER | 8,180,871 | 마스터 |
| SELL_DELIY_ADDR | 22,781,905 | 가장 큰 테이블 |
| SELL_DELIY_ADDR_ADD | 21,801,419 | |
| SELL_DELIY_ADDR_SNAPSHOT | 106,731 | |
| USER_DELIY_ADDR | 3,281,923 | |
| FAN_EVENT_USER | - | |
| ONLINE_EVENT | - | |
| COUNSEL | - | |
| SELL_CER | - | |
| DELIVERY_3PL | - | |
| SELL_EPASS | - | |
| BANK_INOUT | - | |
| ALIMTALK_REQ_HISTORY | - | |

### capybara 스키마 (2개)
| 테이블 | 예상 건수 |
|--------|----------|
| REVIEWS | 12,028 |
| USER_DEVICES | - |

---

## 실행 계획

### Step 1: 사전 준비

#### 1.1 VPN 연결 및 접근 확인
```bash
# VPN 연결 후 RDS 접근 테스트
mysql -h dev-20260115.cluster-ro-cn1qryhj0wq.ap-northeast-2.rds.amazonaws.com -P 3306 -u <username> -p
```

#### 1.2 로컬 Docker MySQL 컨테이너 설정
```bash
# docker-compose 사용 (scripts/db-scrubbing/docker/docker-compose.yml)
cd scripts/db-scrubbing/docker
docker compose up -d
```

### Step 2: 스키마 추출 및 적용

```bash
# Reader 엔드포인트에서 스키마만 추출 (--no-data)
./scripts/db-scrubbing/export_schema.sh

# 로컬 DB에 스키마 적용
./scripts/db-scrubbing/import_schema.sh
```

### Step 3: 샘플 데이터 추출

각 테이블별로 최근 데이터 샘플 추출 (스크립트가 자동으로 처리):

| 테이블 | 추출 건수 | 조건 |
|--------|----------|------|
| USER | 10,000건 | LIMIT 10000 |
| SELL_DELIY_ADDR | 50,000건 | ORDER BY REG_DT DESC LIMIT 50000 |
| SELL_DELIY_ADDR_ADD | JOIN으로 연계 추출 | SELL_DELIY_ADDR의 SELL_DADDR_NO 기준 |
| SELL_DELIY_ADDR_SNAPSHOT | 전체 | 10만건 미만 |
| USER_DELIY_ADDR | 10,000건 | LIMIT 10000 |
| 기타 테이블 | 10,000건 | LIMIT 10000 |
| capybara.REVIEWS | 전체 | 1.2만건 |
| capybara.USER_DEVICES | 10,000건 | LIMIT 10000 |

```bash
# 샘플 데이터 추출 스크립트 실행
./scripts/db-scrubbing/export_sample_data.sh
```

### Step 4: 데이터 로딩

```bash
# 로컬 Docker DB에 데이터 로딩
./scripts/db-scrubbing/import_data.sh
```

### Step 5: 검증

```bash
# 로딩된 데이터 건수 확인
./scripts/db-scrubbing/verify_import.sh
```

---

## 구현 산출물

### 생성할 파일들

| 파일 | 설명 |
|-----|------|
| `docker/docker-compose.yml` | 로컬 MySQL 8.0 컨테이너 설정 |
| `docker/.env.example` | 환경변수 템플릿 (비밀번호 등) |
| `docker/init/00_create_schemas.sql` | hmmall, capybara 스키마 생성 |
| `export_schema.sh` | Aurora에서 테이블 스키마 추출 |
| `export_sample_data.sh` | Aurora에서 샘플 데이터 추출 |
| `import_schema.sh` | 로컬 DB에 스키마 적용 |
| `import_data.sh` | 로컬 DB에 데이터 로딩 |
| `verify_import.sh` | 로딩 결과 검증 |
| `.gitignore` 업데이트 | exports/ 폴더 제외 |

### 최종 디렉토리 구조
```
scripts/db-scrubbing/
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── .env                  # 실제 설정 (git ignore)
│   └── init/
│       └── 00_create_schemas.sql
├── exports/                   # 추출된 데이터 (git ignore)
│   ├── schema.sql
│   └── *.sql
├── export_schema.sh
├── export_sample_data.sh
├── import_schema.sh
├── import_data.sh
├── verify_import.sh
├── 00_analyze.sql
├── 01_delete_old_data.sql
├── 02_scrub_hmmall_core.sql
├── 03_scrub_hmmall_extra.sql
├── 04_scrub_capybara.sql
├── 05_verify.sql
├── run_scrubbing.sh
└── README.md
```

---

## 주의사항

1. **VPN 필수**: Aurora RDS 접근 전 VPN 연결 필수

2. **민감 데이터**: 로컬로 가져오는 데이터에도 개인정보 포함. 추출 후 즉시 scrubbing 스크립트 실행 권장

3. **Reader 엔드포인트 사용**: 데이터 추출 시 Writer가 아닌 Reader 엔드포인트 사용으로 운영 부하 최소화

4. **로컬 포트**: 기존 MySQL과 충돌 방지를 위해 3307 포트 사용

---

## 검증 방법

1. Docker 컨테이너 정상 실행 확인
2. 각 테이블별 데이터 건수 확인
3. 스크럽 스크립트(02~04) 실행 테스트
4. 05_verify.sql로 마스킹 결과 검증
