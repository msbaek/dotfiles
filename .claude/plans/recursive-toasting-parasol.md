# 문서 업데이트 계획: ktown4u-masking

## 배경

라이브러리에서 다음 기능들이 제거됨:
- JPA Converter (8개)
- MyBatis TypeHandler/Interceptor
- @Masked Annotation + MaskingProcessor
- Jackson Module
- GraphQL Instrumentation

현재 남아있는 핵심 기능:
- `Masker` 유틸리티 (8가지 마스킹 메서드)
- `MaskingType` enum
- `MaskingConfig` (전역 활성화/비활성화)
- `MaskingAutoConfiguration` (Spring Boot 자동 설정)
- `crypto/` (Encryptor, Decryptor)

배포 방식 변경:
- JitPack → AWS CodeArtifact

---

## 수정 대상 파일

### 1. README.md (대폭 수정)
**현재 문제점**:
- "지원 기능" 테이블에 JPA, MyBatis, Annotation, Jackson 등 제거된 기능 포함
- JitPack 설치 방법 기재
- 사용법 상세 가이드에 제거된 기능들 설명

**수정 내용**:
- 지원 기능 테이블: 직접 마스킹, 암호화만 유지
- 설치 방법: AWS CodeArtifact로 변경
- 사용법: Masker 유틸리티, 암호화만 유지
- 불필요한 섹션 제거 (JPA, MyBatis, Annotation, Jackson 관련)

### 2. CLAUDE.md (수정)
**현재 문제점**:
- "주요 기능"에 Spring Boot AutoConfiguration 언급 (유지)
- 핵심 파일 구조에 crypto/ 폴더 있음 (유지)

**수정 내용**:
- 큰 수정 불필요, 현재 상태 확인 후 미세 조정

### 3. docs/MASKING-GUIDE.md (수정)
**현재 문제점**:
- 환경별 설정 방법은 유지
- 프로필별 동작 확인 테스트 예시 있음

**수정 내용**:
- JPA, MyBatis, Annotation 관련 내용 있으면 제거
- 단순화된 사용법만 유지

### 4. docs/plan.md (대폭 수정 또는 삭제)
**현재 문제점**:
- Phase 1~6 구현 계획 (대부분 제거된 기능)
- 파일 구조에 제거된 파일들 나열

**수정 내용**:
- 현재 상태 반영하여 대폭 수정 또는 삭제

### 5. docs/2025-12-11-001-implementation-plan.md (삭제 또는 보관)
- 초기 구현 계획 (JPA, MyBatis 등 포함)
- 역사적 기록으로 보관하거나 삭제

### 6. docs/2025-12-11-003-implementation-complete.md (삭제 또는 보관)
- 전체 구현 완료 보고 (제거된 기능 포함)
- 역사적 기록으로 보관하거나 삭제

### 7. docs/2025-12-12-005-test-documentation.md (대폭 수정)
- 제거된 기능의 테스트 설명 제거

---

## 추가할 내용

### AWS CodeArtifact 의존성 추가 방법 (README.md에 추가)

**Gradle (Groovy) - build.gradle**:
```groovy
def fetchCodeArtifactToken() {
    def envToken = System.getenv("CODEARTIFACT_AUTH_TOKEN")
    if (envToken != null && !envToken.isEmpty()) {
        return envToken
    }
    try {
        def process = new ProcessBuilder(
            "aws", "codeartifact", "get-authorization-token",
            "--domain", "ktown4u",
            "--domain-owner", "170023315897",
            "--region", "ap-northeast-1",
            "--query", "authorizationToken",
            "--output", "text"
        ).start()
        return process.inputStream.text.trim()
    } catch (Exception e) {
        return ""
    }
}

repositories {
    mavenLocal()
    mavenCentral()
    maven {
        name = "CodeArtifact"
        url = uri("https://ktown4u-170023315897.d.codeartifact.ap-northeast-1.amazonaws.com/maven/ktown4u-masking/")
        credentials {
            username = "aws"
            password = fetchCodeArtifactToken()
        }
    }
}

dependencies {
    implementation 'com.ktown4u:ktown4u-masking:v1.1.1'
}
```

**Gradle (Kotlin DSL) - build.gradle.kts**:
```kotlin
val codeArtifactToken: String by lazy {
    System.getenv("CODEARTIFACT_AUTH_TOKEN")
        ?: ProcessBuilder(
            "aws", "codeartifact", "get-authorization-token",
            "--domain", "ktown4u",
            "--domain-owner", "170023315897",
            "--region", "ap-northeast-1",
            "--query", "authorizationToken",
            "--output", "text"
        ).start().inputStream.bufferedReader().readText().trim()
}

repositories {
    mavenLocal()
    mavenCentral()
    maven {
        name = "CodeArtifact"
        url = uri("https://ktown4u-170023315897.d.codeartifact.ap-northeast-1.amazonaws.com/maven/ktown4u-masking/")
        credentials {
            username = "aws"
            password = codeArtifactToken
        }
    }
}

dependencies {
    implementation("com.ktown4u:ktown4u-masking:v1.1.1")
}
```

---

## 작업 순서

### 1. README.md 전면 수정
**경로**: `/Users/msbaek/git/kt4u/ktown4u-masking/README.md`

- 지원 기능 테이블: 직접 마스킹, 암호화만 유지
- 설치 방법: JitPack → AWS CodeArtifact
- 사용법: Masker 유틸리티 + 암호화만 유지
- 제거할 섹션:
  - JPA Entity 적용 (섹션 2, 3)
  - MyBatis 적용 (섹션 3)
  - Annotation 기반 마스킹 (섹션 4)
  - Jackson JSON 직렬화 마스킹 (섹션 5)
  - 테스트 파일 구조 (제거된 테스트 파일들)
  - 프로젝트별 적용 체크리스트

### 2. CLAUDE.md 수정
**경로**: `/Users/msbaek/git/kt4u/ktown4u-masking/CLAUDE.md`

- 핵심 파일 구조 현행화
- 제거된 기능 언급 삭제

### 3. docs/MASKING-GUIDE.md 수정
**경로**: `/Users/msbaek/git/kt4u/ktown4u-masking/docs/MASKING-GUIDE.md`

- 제거된 기능 관련 내용 정리
- 단순한 Masker 사용법 중심으로 유지

### 4. docs/ 폴더 정리 (삭제)
**삭제 대상**:
- `docs/plan.md` - 이전 구현 계획
- `docs/2025-12-11-001-implementation-plan.md` - 초기 구현 계획
- `docs/2025-12-11-002-phase1-masker-complete.md` - Phase 1 완료 보고
- `docs/2025-12-11-003-implementation-complete.md` - 전체 구현 완료 요약
- `docs/2025-12-12-005-test-documentation.md` - 테스트 문서

**유지**:
- `docs/MASKING-GUIDE.md` - 사용자 가이드 (수정)
- `docs/2025-12-11-004-masking-rules-reference.md` - 마스킹 규칙 참고 (유지)

### 5. CHANGELOG.md 생성
**경로**: `/Users/msbaek/git/kt4u/ktown4u-masking/CHANGELOG.md`

주요 변경사항 기록:
- v1.1.1: 라이브러리 단순화 (JPA, MyBatis, Annotation, Jackson 제거)
- 배포 방식: JitPack → AWS CodeArtifact

### 6. 최종 검토
- 모든 문서 간 일관성 확인
- 버전 정보 동기화 확인

---

## 수정할 파일 목록 (요약)

| 파일 | 작업 |
|------|------|
| README.md | 대폭 수정 |
| CLAUDE.md | 수정 |
| docs/MASKING-GUIDE.md | 수정 |
| docs/plan.md | 삭제 |
| docs/2025-12-11-001-*.md | 삭제 |
| docs/2025-12-11-002-*.md | 삭제 |
| docs/2025-12-11-003-*.md | 삭제 |
| docs/2025-12-12-005-*.md | 삭제 |
| CHANGELOG.md | 신규 생성 |
