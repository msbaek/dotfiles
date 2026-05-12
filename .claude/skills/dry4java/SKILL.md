---
name: dry4java
description: |
  This skill should be used when the user asks to find duplicate Java code, check DRY violations,
  "중복 코드 찾아줘", "dry4java 실행", "구조적으로 유사한 코드 찾아줘", "중복 선언 분석",
  "코드 중복도 확인", "copy-paste 패턴 찾기", or mentions structural similarity, Jaccard similarity,
  DRY (Don't Repeat Yourself) in Java codebase context.
  Java 소스 코드의 구조적 유사도를 AST 기반으로 측정하여 중복 선언 후보를 찾고 리팩터링 방향을 제시.
---

# dry4java Skill

Java 소스의 선언(메서드·클래스·생성자·람다 등)을 AST 정규화 후 Jaccard 유사도로 비교하여
중복 후보를 발견하고 리팩터링 우선순위를 제시한다.

## 유사도 계산 방식

```
score = shared fingerprints / all fingerprints in either candidate
```

- **정규화**: 이름과 리터럴 값을 제거, Java 문법 구조만 남김
- **비교 단위**: 클래스·인터페이스·레코드·열거형·메서드·생성자·필드·람다·초기화 블록 등 모든 선언
- **기본 임계값**: 0.82 (82% 이상 유사하면 중복 후보)

## 도구 위치

```
JAR=~/git/uncle-bob/dry4java/target/dry4java-0.1.0-SNAPSHOT.jar
```

## 실행 방법

경로를 지정하지 않으면 현재 디렉토리의 `src/`를 자동 스캔.

```bash
# 현재 프로젝트 src/ 전체 분석 (기본)
java -jar $JAR

# 특정 파일 또는 디렉토리 지정
java -jar $JAR src/main/java/com/example/

# 여러 경로 동시 분석
java -jar $JAR module-a/src module-b/src

# 임계값 조정 (더 유사한 것만, 기본 0.82)
java -jar $JAR --threshold 0.90

# 더 짧은 선언도 포함 (기본 min-lines=4)
java -jar $JAR --min-lines 2

# EDN 형식 출력 (프로그래밍 처리용)
java -jar $JAR --edn

# 복합 옵션
java -jar $JAR --threshold 0.85 --min-lines 6 src/main/java/
```

## 옵션 참조

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--threshold N` | 0.82 | 유사도 최솟값 (0.0~1.0) |
| `--min-lines N` | 4 | 비교 대상 최소 소스 라인 수 |
| `--min-nodes N` | 20 | 비교 대상 최소 AST 노드 수 |
| `--format text\|edn` | text | 출력 형식 |
| `--edn` | — | `--format edn`과 동일 |
| `--text` | — | `--format text`와 동일 |

## 출력 형식

**text (기본)**
```
DUPLICATE score=0.89
  src/main/java/app/Invoice.java:12-25
  src/main/java/app/Receipt.java:30-44
```

**EDN**
```clojure
{:candidates
 [{:score 0.8909090909090909
   :left {:file "src/main/java/app/Invoice.java", :start-line 12, :end-line 25}
   :right {:file "src/main/java/app/Receipt.java", :start-line 30, :end-line 44}
   :left-nodes 88
   :right-nodes 91}]}
```

## 유사도 등급과 리팩터링 전략

| 유사도 범위 | 등급 | 권장 액션 |
|-------------|------|-----------|
| 0.95 ~ 1.00 | 🔴 거의 동일 | Extract Method / Extract Class + 재사용 |
| 0.85 ~ 0.94 | 🟡 높은 유사 | Template Method Pattern / Strategy Pattern |
| 0.82 ~ 0.84 | 🟢 중복 후보 | 검토 후 공통 추상화 고려 |

## 리팩터링 매핑

| 중복 패턴 | 권장 리팩터링 |
|-----------|--------------|
| 동일 로직, 다른 타입 처리 | `msbaek-tdd:replace-conditional-with-poly` |
| 반복되는 반복문 패턴 | `msbaek-tdd:replace-loop-with-pipeline` |
| 유사한 조건 구조 | `msbaek-tdd:decompose-conditional` |
| 동일 계산 로직이 여러 메서드에 분산 | `msbaek-tdd:extract-method-object` |
| 유사한 초기화·설정 코드 | `msbaek-tdd:introduce-parameter-object` |
| 유사 클래스 간 중복 | Extract Superclass / Extract Interface |

## 워크플로우

### 빠른 스캔 (기본)

```bash
cd <project-root>
java -jar ~/git/uncle-bob/dry4java/target/dry4java-0.1.0-SNAPSHOT.jar
```

### 임계값 낮춰서 더 많은 후보 탐색

```bash
java -jar ~/git/uncle-bob/dry4java/target/dry4java-0.1.0-SNAPSHOT.jar --threshold 0.75
```

### 개선 후 재확인

```bash
java -jar ~/git/uncle-bob/dry4java/target/dry4java-0.1.0-SNAPSHOT.jar src/main/java/com/example/
```

## 주의사항

- Java 파일이 없는 경로를 지정하면 결과 없이 종료
- `src/`가 없는 디렉토리에서 경로 미지정 실행 시 0건 출력
- 매우 짧은 메서드(기본 4줄 미만)는 노이즈 방지를 위해 분석 제외
- AST 노드 수가 `--min-nodes`(기본 20) 미만인 선언도 제외
- JAR 미존재 시: `cd ~/git/uncle-bob/dry4java && mvn -q -DskipTests package`로 빌드

## Sub-agent 위임

분석 + 상세 해석 + 리팩터링 계획이 필요하면 `dry4java-analyzer` agent에 위임:
→ 결과 파싱, 소스 코드 검사, 리팩터링 우선순위 전체를 처리.
