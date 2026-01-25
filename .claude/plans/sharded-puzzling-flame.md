# goods_category_dm Materialized View 생성 계획

## 요약
새 Databricks 클러스터(sandbox.msbaek)에 goods_category_dm을 Materialized View로 생성

## 환경 정보
- **카탈로그/스키마**: `sandbox.msbaek`
- **소스 테이블**: `goods_grp` (이미 streaming table로 존재)
- **대상 객체**: `goods_category_dm` (Materialized View)
- **스키마 호환성**: 기존과 완전 호환 필수

## 생성할 SQL 파일

### `goods_category_dm.sql`

```sql
use catalog sandbox;
use schema msbaek;

CREATE OR REFRESH MATERIALIZED VIEW goods_category_dm (
  category_no COMMENT '카테고리 번호 (PK)',
  category_type COMMENT '1단계 분류 (브랜드/소속사/아티스트 등)',
  category_class1 COMMENT '2단계 분류',
  category_class2 COMMENT '3단계 분류',
  category_class3 COMMENT '4단계 분류',
  category_nm COMMENT '현재 카테고리명',
  category_act_yn COMMENT '활성화 여부 (Y/N)',
  reg_dt COMMENT '등록일시',
  add_time COMMENT 'CDC 추가 시간'
)
COMMENT '상품 카테고리 데이터마트 - 5단계 계층 구조 (category_type → category_class1 → category_class2 → category_class3)'
AS
SELECT
  gg.grp_no AS category_no,
  p1.grp_nm AS category_type,
  p2.grp_nm AS category_class1,
  p3.grp_nm AS category_class2,
  p4.grp_nm AS category_class3,
  gg.grp_nm AS category_nm,
  gg.act_yn AS category_act_yn,
  gg.reg_dt,
  gg.ADD_TIME AS add_time
FROM goods_grp gg
LEFT OUTER JOIN goods_grp p1
  ON CAST(p1.grp_no AS STRING) = split_part(gg.path, '.', 2)
  AND p1.depth <> gg.depth
LEFT JOIN goods_grp p2
  ON CAST(p2.grp_no AS STRING) = split_part(gg.path, '.', 3)
LEFT OUTER JOIN goods_grp p3
  ON CAST(p3.grp_no AS STRING) = split_part(gg.path, '.', 4)
LEFT OUTER JOIN goods_grp p4
  ON CAST(p4.grp_no AS STRING) = split_part(gg.path, '.', 5)
WHERE gg.del_yn = 'N';
```

## 출력 스키마 (기존 호환)

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| category_no | BIGINT | 카테고리 번호 (PK) |
| category_type | STRING | 1단계 (브랜드/소속사/아티스트 등) |
| category_class1 | STRING | 2단계 |
| category_class2 | STRING | 3단계 |
| category_class3 | STRING | 4단계 |
| category_nm | STRING | 현재 카테고리명 |
| category_act_yn | STRING | 활성화 여부 |
| reg_dt | TIMESTAMP | 등록일시 |
| add_time | TIMESTAMP | CDC 추가 시간 |

## 주의사항

1. **타입 캐스팅**: `split_part()` 결과는 STRING, `grp_no`는 BIGINT이므로 조인 시 `CAST(grp_no AS STRING)` 필요
2. **MV 제약사항**: Databricks MV는 streaming table을 소스로 사용 가능하나, 복잡한 self-join 시 성능 확인 필요
3. **Refresh**: `CREATE OR REFRESH` 사용으로 파이프라인 실행 시마다 자동 갱신 (없으면 생성, 있으면 refresh)

## 검증 방법

```sql
-- 1. 생성 확인
DESCRIBE EXTENDED sandbox.msbaek.goods_category_dm;

-- 2. 데이터 건수 확인
SELECT COUNT(*) FROM sandbox.msbaek.goods_category_dm;

-- 3. 스키마 호환성 확인 (기존 쿼리 패턴)
SELECT
  category_no,
  category_type,
  category_class1,
  category_class2,
  category_class3,
  category_nm,
  category_act_yn
FROM sandbox.msbaek.goods_category_dm
WHERE category_type = '브랜드'
LIMIT 10;

-- 4. 계층 구조 정합성 확인
SELECT category_type, COUNT(*)
FROM sandbox.msbaek.goods_category_dm
GROUP BY category_type;
```

## 파일 위치
- 생성 경로: `/Users/msbaek/git/kt4u/databricks-notebook/Pipeline/category/sql/goods_category_dm.sql`
