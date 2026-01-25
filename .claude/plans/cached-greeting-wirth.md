# Databricks Jobs, Tasks, Pipelines 개념 정리

## 개요

Vault의 STUDY/DataBricks 문서들을 분석한 결과, Databricks의 워크로드 관리 체계는 **Lakeflow**라는 통합 브랜드 아래 다음과 같이 구성됩니다.

---

## 핵심 개념 및 포함 관계

### 계층 구조 (상위 → 하위)

```
┌─────────────────────────────────────────────────────────────┐
│                     Databricks Workflows                     │
│            (전체 워크로드 관리를 포괄하는 개념)                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Job (= Workflow)                        │    │
│  │         최상위 스케줄링/오케스트레이션 단위            │    │
│  │                                                     │    │
│  │  ┌─────────────────────────────────────────────┐   │    │
│  │  │                  Task                        │   │    │
│  │  │            DAG의 노드 (실행 단위)              │   │    │
│  │  │                                              │   │    │
│  │  │  - Notebook Task                            │   │    │
│  │  │  - SQL Task                                 │   │    │
│  │  │  - Python Task                              │   │    │
│  │  │  - Pipeline Task (DLT 파이프라인 실행)        │   │    │
│  │  │  - 다른 Job 포함 가능 (거의 안 씀)             │   │    │
│  │  └─────────────────────────────────────────────┘   │    │
│  │                                                     │    │
│  │  Job : Task = 1 : N                                │    │
│  │  Job : Pipeline = 1 : N                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 상세 개념 정리

### 1. Job (= Workflow)
**정의**: Databricks에서 **최상위 스케줄링/오케스트레이션 단위**

**특징**:
- 스케줄링, 파라미터 설정, 알림 관리
- 여러 개의 Task로 구성됨
- 다른 Job을 포함할 수 있음 (실무에서는 거의 사용 안 함)
- DAG(Directed Acyclic Graph) 형태로 Task들의 실행 순서 정의

**스케줄링 옵션**:
| 트리거 타입 | 설명 |
|------------|------|
| Manual | 수동 실행 |
| Scheduled | Cron 표현식 기반 정기 실행 |
| File Arrival | 특정 경로에 파일 도착 시 실행 |
| Continuous | 지속적 실행 |

**출처**: `2025-databricks-인수인계.md` (Line 47-55)

---

### 2. Task
**정의**: DAG의 **노드**이자 실제 작업을 수행하는 **실행 단위**

**Task 유형**:
- **Notebook Task**: 노트북 실행
- **SQL Task**: SQL 쿼리 실행
- **Python Task**: Python 스크립트 실행
- **Pipeline Task**: Delta Live Tables 파이프라인 실행
- **JAR Task**: JAR 파일 실행
- **Spark Submit Task**: Spark 작업 제출

**의존성 설정**:
```yaml
tasks:
  - task_key: create_bronze_table
    notebook_task:
      notebook_path: ./src/create_bronze_table.py
  - task_key: create_silver_table
    depends_on:
      - task_key: create_bronze_table
    notebook_task:
      notebook_path: ./src/create_silver_table.py
```

**출처**: `3.Automated-Deployment-with-DAB-통합.md` (Line 77-85)

---

### 3. Pipeline (Lakeflow Declarative Pipelines, 구 Delta Live Tables)
**정의**: **선언적 방식으로 ETL 파이프라인을 정의**하는 프레임워크

**핵심 특징**:
- 선언적 프로그래밍: "무엇(What)"을 정의, "어떻게(How)"는 자동화
- 증분 처리(Incremental Processing) 지원
- 내장 데이터 품질 검증(Expectations)
- 배치와 스트리밍 통합

**Pipeline 구성 요소**:

| 구성 요소 | 설명 |
|----------|------|
| **Streaming Table** | 증분 데이터 처리용 테이블 (새 데이터만 처리) |
| **Materialized View** | 미리 계산된 결과 저장 (변경 시 재계산) |
| **Temporary View** | 파이프라인 내 중간 결과 (Unity Catalog 미등록) |
| **View** | 물리적 데이터 없는 가상 테이블 (Unity Catalog 등록) |

**Pipeline vs Job 관계**:
```
Job : Pipeline = 1 : N
Pipeline : Task = 1 : 1 (일반적)
```

**출처**: `Build Data Pipelines with Lakeflow DeclarativePipelines.md`, `5.Build Data Pipelines with Lakeflow-Declarative-Pipelines-Labs-통합.md`

---

## Lakeflow 통합 브랜드 구조

```
Lakeflow (통합 브랜드)
├── Lakeflow Connect (Ingestion Pipeline)
│   └── 외부 데이터 소스 연결/수집
├── Lakeflow Declarative Pipelines (ETL Pipeline)
│   └── 선언적 ETL 파이프라인 (구 Delta Live Tables)
└── Lakeflow Jobs (Orchestration)
    └── 워크플로우 오케스트레이션 및 스케줄링
```

**출처**: `SQL Analytics on Databricks-정리.md` (Line 36-55)

---

## 포함 관계 정리

| 관계 | 비율 | 설명 |
|------|------|------|
| **Job : Task** | 1 : N | Job은 여러 Task로 구성됨 |
| **Job : Pipeline** | 1 : N | Job이 여러 Pipeline을 실행할 수 있음 |
| **Pipeline : Task** | 1 : 1 | Pipeline은 Task의 한 유형 |
| **Job : Job** | 1 : N | Job이 다른 Job 포함 가능 (거의 사용 안 함) |

---

## 실무 적용 예시 (Ktown4u 아키텍처)

```
RDS Cluster → AWS DMS → S3 (ktown4u-datalake-origin)
                              ↓
                    Databricks Autoloader (1분 마이크로배치)
                              ↓
                    Delta Live Tables (Pipeline)
                              ↓
                    Delta Tables (Bronze → Silver → Gold)
```

**GitHub 저장소 구조**:
```
databricks-notebook/
├── Pipeline/           # 주제별 파이프라인
│   ├── {topic}/
│   │   ├── dlt/       # Delta Live Tables 파이프라인
│   │   └── job/       # Workflow 파이프라인
├── module/            # 데이터소스 R/W 메소드
└── transform/         # 데이터 변환 로직
```

**출처**: `SYSTEM_ARCHITECTURE.md` (Line 113-125)

---

## 참조 문서 목록

| 문서명 | 경로 |
|--------|------|
| 인수인계 문서 | `work-log/2025-databricks-인수인계.md` |
| 시스템 아키텍처 | `STUDY/DataBricks/SYSTEM_ARCHITECTURE.md` |
| SQL Analytics 정리 | `STUDY/DataBricks/공식강의/1.SQL-Analytics/SQL Analytics on Databricks-정리.md` |
| DAB 통합 가이드 | `STUDY/DataBricks/공식강의/통합/3.Automated-Deployment-with-DAB-통합.md` |
| Lakeflow Pipelines Labs | `STUDY/DataBricks/공식강의/통합/5.Build Data Pipelines with Lakeflow-Declarative-Pipelines-Labs-통합.md` |
| Lakeflow Pipelines 강의 | `STUDY/DataBricks/공식강의/5.Build Data Pipelines with Lakeflow Declarative Pipelines/Build Data Pipelines with Lakeflow DeclarativePipelines.md` |

---

## Uncertainty Map (불확실성 지도)

### 덜 확신하는 부분
- `Pipeline : Task = 1 : 1`에 대해 일부 문서에서는 1:N이라고 언급 (LLM 답변 기준)
- Lakeflow 브랜딩이 2024-2025년 새로 도입되어 일부 문서는 구 명칭(Delta Live Tables, Databricks Workflows) 사용

### 추가 확인 필요
- 특정 사용 사례에서 Job이 다른 Job을 포함하는 패턴이 사용되는지
- 스트리밍과 배치 혼합 파이프라인에서의 Task-Pipeline 관계
