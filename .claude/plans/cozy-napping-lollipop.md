# ktown4u-masking 라이브러리 capybara 적용 계획

## 개요
ktown4u-masking 라이브러리(v1.2.0)를 capybara 프로젝트에 적용하여 개인정보 마스킹 기능을 강화합니다.

## 정책 결정 사항
- **관리자 API**: 기본 마스킹 적용 (X-Skip-Masking 헤더로 해제 가능)
- **username 필드**: maskName() 적용 (홍길동 → 홍*동)
- **deviceId**: 마스킹 대상에 포함

---

## 진행 상황

| Phase | 상태 | 완료일 |
|-------|------|-------|
| Phase 0: 문서 개선 | ✅ 완료 | 2026-01-23 |
| Phase 1: 빌드 설정 | ✅ 완료 | 2026-01-23 |
| Phase 2: TDD 테스트 | ✅ 완료 | 2026-01-23 |
| Phase 3: 마스킹 적용 | ✅ 완료 | 2026-01-23 |
| Phase 4: 구현 | ✅ 완료 | 2026-01-23 |
| Phase 5: API 테스트 | ⏳ 대기 | - |
| Phase 6: 검증 | ⏳ 대기 | - |

### 다음 단계
**Phase 5: API 테스트** - curl/GraphiQL로 마스킹 동작 확인

---

## Phase 0: ktown4u-masking 문서 개선 ✅ 완료

> **목적**: 다른 프로젝트에서 쉽게 의존성을 추가할 수 있도록 문서 개선
> **완료일**: 2026-01-23

### 완료된 작업

#### 0.1 README.md 업데이트 ✅
**파일**: `~/git/kt4u/ktown4u-masking/README.md`

**추가된 내용:**
1. ✅ **빠른 설정 (Copy & Paste) 섹션** - 3단계 복사-붙여넣기 가이드
2. ✅ **Lazy loading 패턴** - `ext.codeArtifactToken` + `getCodeArtifactToken()` 추가
3. ✅ **URL 오버라이드** - `CODEARTIFACT_REPOSITORY_URL` 환경 변수 지원
4. ✅ **상세 에러 처리** - `process.waitFor()` exit code 확인 + 경고 로그
5. ✅ **환경 변수 섹션** - 테이블 + 사용 예시
6. ✅ **Kotlin DSL 개선** - exit code 확인, URL 오버라이드 추가

#### 0.2 Copy-Paste 가능한 스니펫 섹션 ✅
- "설치 방법" 최상단에 "빠른 설정" 섹션 추가
- 토큰 함수 → repositories → dependencies 3단계 분리

### 피드백 대기 사항
- Copy & Paste 섹션 위치 적절성
- 상세 설명 버전 유지 여부 (중복 우려)
- Kotlin DSL 필요성 확인

---

### 참고: Phase 0 원본 계획 (보존)

### 0.1 README.md 업데이트
**파일**: `~/git/kt4u/ktown4u-masking/README.md`

현재 문서에 누락된 내용 추가:
1. **Lazy loading 패턴**: 토큰을 한 번만 획득하여 불필요한 AWS API 호출 방지
2. **URL 오버라이드**: `CODEARTIFACT_REPOSITORY_URL` 환경 변수 지원
3. **상세 에러 처리**: exit code 확인 및 경고 로그

```groovy
// ✅ 개선된 버전 (lazy loading + URL 오버라이드)
// AWS CodeArtifact 토큰을 자동으로 가져오는 함수
def fetchCodeArtifactToken() {
    // 환경 변수가 있으면 우선 사용
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

        def token = process.inputStream.text.trim()
        def exitCode = process.waitFor()

        if (exitCode == 0 && !token.isEmpty()) {
            return token
        } else {
            logger.warn("AWS CodeArtifact 토큰 획득 실패 (exit code: ${exitCode})")
            return ""
        }
    } catch (Exception e) {
        logger.warn("AWS CLI 실행 실패: ${e.message}")
        return ""
    }
}

// 토큰은 lazy하게 한 번만 가져옴
ext.codeArtifactToken = null
def getCodeArtifactToken() {
    if (ext.codeArtifactToken == null) {
        ext.codeArtifactToken = fetchCodeArtifactToken()
    }
    return ext.codeArtifactToken
}

repositories {
    mavenLocal()
    mavenCentral()
    maven {
        name = "CodeArtifact"
        // URL 오버라이드 지원
        url = uri(System.getenv("CODEARTIFACT_REPOSITORY_URL")
            ?: "https://ktown4u-170023315897.d.codeartifact.ap-northeast-1.amazonaws.com/maven/ktown4u-masking/")
        credentials {
            username = "aws"
            password = getCodeArtifactToken()
        }
    }
}

dependencies {
    implementation 'com.ktown4u:ktown4u-masking:v1.2.0'
}
```

### 0.2 Copy-Paste 가능한 스니펫 섹션 추가

```markdown
## 빠른 설정 (Copy & Paste)

아래 코드를 `build.gradle`의 `repositories` 블록 위에 붙여넣으세요:

\`\`\`groovy
// === ktown4u-masking 의존성 설정 (시작) ===
// 이 블록을 build.gradle의 configurations 블록 다음에 붙여넣으세요

def fetchCodeArtifactToken() { ... }
ext.codeArtifactToken = null
def getCodeArtifactToken() { ... }
// === ktown4u-masking 의존성 설정 (끝) ===
\`\`\`
```

---

## Phase 1: 빌드 설정 ✅ 완료

> **참고**: git commit `0cc135bd` 기반
> **완료일**: 2026-01-23

### 완료된 작업
- ✅ AWS CodeArtifact 토큰 자동 획득 함수 추가 (`fetchCodeArtifactToken`, `getCodeArtifactToken`)
- ✅ CodeArtifact maven repository 설정 추가
- ✅ `com.ktown4u:ktown4u-masking:v1.2.0` 의존성 추가
- ✅ 빌드 테스트 성공 (`./gradlew build -x test`)

### 참고: Phase 1 원본 계획 (보존)

### 1.1 AWS CodeArtifact 토큰 자동 획득 함수 추가
**파일**: `build.gradle` (configurations 블록 다음에 추가)

```groovy
// AWS CodeArtifact 토큰을 자동으로 가져오는 함수
def fetchCodeArtifactToken() {
    // 환경 변수가 있으면 우선 사용
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

        def token = process.inputStream.text.trim()
        def exitCode = process.waitFor()

        if (exitCode == 0 && !token.isEmpty()) {
            return token
        } else {
            logger.warn("AWS CodeArtifact 토큰 획득 실패 (exit code: ${exitCode})")
            return ""
        }
    } catch (Exception e) {
        logger.warn("AWS CLI 실행 실패: ${e.message}")
        return ""
    }
}

// 토큰은 lazy하게 한 번만 가져옴
ext.codeArtifactToken = null
def getCodeArtifactToken() {
    if (ext.codeArtifactToken == null) {
        ext.codeArtifactToken = fetchCodeArtifactToken()
    }
    return ext.codeArtifactToken
}
```

### 1.2 Repository 설정
```groovy
repositories {
    mavenLocal()
    mavenCentral()
    maven {
        name = "CodeArtifact"
        url = uri(System.getenv("CODEARTIFACT_REPOSITORY_URL")
            ?: "https://ktown4u-170023315897.d.codeartifact.ap-northeast-1.amazonaws.com/maven/ktown4u-masking/")
        credentials {
            username = "aws"
            password = getCodeArtifactToken()
        }
    }
}
```

### 1.3 의존성 추가
```groovy
dependencies {
    // ktown4u-masking library
    implementation 'com.ktown4u:ktown4u-masking:v1.2.0'
}
```

### 1.4 토큰 획득 방식
1. **환경 변수 우선**: `CODEARTIFACT_AUTH_TOKEN` 환경 변수가 있으면 사용
2. **AWS CLI 자동 호출**: 환경 변수가 없으면 AWS CLI로 토큰 자동 획득
3. **Lazy Loading**: 빌드 시 한 번만 토큰 획득 (불필요한 AWS API 호출 방지)

### 1.5 환경 변수 (선택적, 수동 설정 시)
```bash
# 수동으로 토큰 설정 (선택적)
export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
    --domain ktown4u --domain-owner 170023315897 \
    --region ap-northeast-1 --query authorizationToken --output text)

# Repository URL 오버라이드 (선택적)
export CODEARTIFACT_REPOSITORY_URL="https://..."
```

---

## Phase 2: TDD - 테스트 먼저 작성 ✅ 완료

> **완료일**: 2026-01-23

### 완료된 작업

#### 2.1 MaskingLibraryMigrationTest.java ✅
**파일**: `src/test/java/com/ktown4u/capybara/masking/MaskingLibraryMigrationTest.java`

테스트 케이스:
- maskUserId: 이메일/일반/짧은 ID/null/empty 처리
- maskName: 한글 2-4자, 영문 이름, null 처리
- maskEmail: 일반/긴 로컬파트 이메일
- 기존 capybara Masker와의 호환성 비교 문서화

**주요 발견 - 기존 vs 새 라이브러리 차이:**
| 케이스 | 기존 capybara | ktown4u-masking |
|--------|--------------|-----------------|
| `hyemin916@ktown4u.com` | `hye******` | `hy*******@ktown4u.com` |
| `hyemin916` | `hye******` | `hy*******` |

#### 2.2 MaskingHeaderControlTest.java ✅
**파일**: `src/test/java/com/ktown4u/capybara/masking/MaskingHeaderControlTest.java`

테스트 케이스:
- 기본 마스킹 동작 (isEnabled=true)
- 마스킹 해제 시뮬레이션 (X-Skip-Masking: true)
- ThreadLocal 격리 테스트
- MaskingFilter 동작 시뮬레이션

### 참고: Phase 2 원본 계획 (보존)

### 2.1 마스킹 라이브러리 마이그레이션 테스트
**파일**: `src/test/java/com/ktown4u/capybara/masking/MaskingLibraryMigrationTest.java`

```java
@DisplayName("ktown4u-masking 라이브러리 마이그레이션 테스트")
class MaskingLibraryMigrationTest {

    @Test
    @DisplayName("이메일 형식 userId 마스킹: user@example.com → us**@example.com")
    void maskUserId_email();

    @Test
    @DisplayName("일반 userId 마스킹: username01 → use*******")
    void maskUserId_normal();

    @Test
    @DisplayName("이름 마스킹: 홍길동 → 홍*동")
    void maskName();

    @Test
    @DisplayName("deviceId 마스킹: ABC123XYZ → ABC*****Z")
    void maskDeviceId();
}
```

### 2.2 HTTP 헤더 기반 마스킹 제어 테스트
**파일**: `src/test/java/com/ktown4u/capybara/masking/MaskingHeaderControlTest.java`

```java
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@DisplayName("HTTP 헤더 기반 마스킹 제어 - API 사용 매뉴얼")
class MaskingHeaderControlTest {

    @Nested
    @DisplayName("기본 마스킹 동작")
    class DefaultMasking {
        @Test
        @DisplayName("헤더 없음 → 마스킹 적용")
        void noHeader_maskingEnabled();
    }

    @Nested
    @DisplayName("마스킹 해제 (X-Skip-Masking: true)")
    class SkipMasking {
        @Test
        @DisplayName("X-Skip-Masking: true → 원본 데이터 반환")
        void skipHeader_maskingDisabled();
    }
}
```

### 2.3 GraphQL API 마스킹 테스트
**파일**: `src/test/java/com/ktown4u/capybara/masking/GraphQLMaskingTest.java`

테스트 대상 API:
- `reviews()` - userId, username 마스킹 확인
- `reviewsForAdmin()` - 기본 마스킹 + 헤더로 해제 확인
- `comments()` - userId, userName 마스킹 확인
- `commentsForAdmin()` - 기본 마스킹 + 헤더로 해제 확인
- `contentComments()` - userId 마스킹 확인
- `eventComments()` - userId 마스킹 확인

---

## Phase 3: 마스킹 적용 대상

### 3.1 기존 Masker 사용 위치 (마이그레이션 필요)

| 파일 | 마스킹 대상 | 현재 | 변경 |
|-----|-----------|------|------|
| `ReviewDto.java` | userId | capybara Masker | library Masker |
| `ReviewDto.java` | username | 없음 | maskName() 추가 |
| `ReviewCommentDto.java` | userId | capybara Masker | library Masker |
| `ReviewCommentDto.java` | userName | 없음 | maskName() 추가 |
| `ContentComment.java` | userId | capybara Masker | library Masker |
| `PagedEventComments.java` | userId | capybara Masker | library Masker |
| `CreateEventComment.java` | userId | capybara Masker | library Masker |
| `CreateReview.java` | userId | capybara Masker | library Masker |

### 3.2 신규 마스킹 적용 대상

| 파일 | 마스킹 대상 | 적용 메서드 |
|-----|-----------|-----------|
| `ContentItemCommentDto.java` | userId | maskUserId() |
| `PagedReviews.java` (Admin) | userId, username | 조건부 마스킹 |
| `PagedReviewComments.java` (Admin) | userId, userName | 조건부 마스킹 |
| `UserDevice.java` | deviceId | maskUserId() |

---

## Phase 4: 구현 순서

### Step 1: 빌드 설정 (build.gradle)
- AWS CodeArtifact repository 추가
- ktown4u-masking:v1.2.0 의존성 추가
- 빌드 테스트: `./gradlew build`

### Step 2: MaskingFilter 자동 설정 확인
- `masking.header-based=true` (기본값) 확인
- MaskingAutoConfiguration 동작 확인

### Step 3: 기존 Masker 마이그레이션
- `com.ktown4u.capybara.Masker` → `com.ktown4u.masking.Masker`
- import 문 변경 (6개 파일)
- 기존 `Masker.java` 파일 삭제

### Step 4: username 마스킹 추가
- `ReviewDto.withMaskedUserId()` → `withMaskedUserInfo()` (userId + username)
- `ReviewCommentDto` 동일 적용

### Step 5: 신규 마스킹 적용
- `ContentItemCommentDto`에 `withMaskedUserId()` 추가
- `GetContentComment`에서 마스킹 메서드 호출

### Step 6: 관리자 API 마스킹
- `PagedReviews`, `PagedReviewComments`에 조건부 마스킹 적용
- `MaskingConfig.isEnabled()` 확인 후 마스킹

### Step 7: DeviceId 마스킹
- `UserDevice` 응답 시 deviceId 마스킹

---

## Phase 5: API 테스트 (curl/GraphiQL)

### 5.1 curl 테스트 예시

```bash
# 마스킹 적용 (기본)
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"query":"{ reviews(productNo:1,page:0,size:5,sortBy:\"createdAt\") { userId username } }"}'
# 결과: {"userId":"hye******","username":"홍*동"}

# 마스킹 해제 (관리자/DMZ)
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -H "X-Skip-Masking: true" \
  -d '{"query":"{ reviewsForAdmin(page:0,size:5,sortBy:\"createdAt\") { userId username } }"}'
# 결과: {"userId":"hyemin916@ktown4u.com","username":"홍길동"}
```

### 5.2 GraphiQL 테스트
1. http://localhost:8080/graphiql 접속
2. 하단 Headers 탭에서 `{"X-Skip-Masking": "true"}` 입력
3. 쿼리 실행하여 원본 데이터 확인

### 5.3 HTTP 파일 테스트
**파일**: `src/test/resources/masking-api-test.http`

---

## Phase 6: 검증

### 6.1 단위 테스트
```bash
./gradlew test --tests '*Masking*'
```

### 6.2 통합 테스트
```bash
./gradlew integrationTest
```

### 6.3 수동 API 테스트
- GraphiQL에서 주요 API 확인
- curl로 헤더 기반 제어 확인

---

## 주요 파일 목록

### 수정 대상
1. `build.gradle` - CodeArtifact + 의존성
2. `src/main/java/com/ktown4u/capybara/Masker.java` - 삭제
3. `src/main/java/com/ktown4u/capybara/projections/ReviewDto.java`
4. `src/main/java/com/ktown4u/capybara/projections/ReviewCommentDto.java`
5. `src/main/java/com/ktown4u/capybara/domain/ContentComment.java`
6. `src/main/java/com/ktown4u/capybara/projections/ContentItemCommentDto.java`
7. `src/main/java/com/ktown4u/capybara/application/PagedEventComments.java`
8. `src/main/java/com/ktown4u/capybara/application/CreateEventComment.java`
9. `src/main/java/com/ktown4u/capybara/application/CreateReview.java`
10. `src/main/java/com/ktown4u/capybara/application/PagedReviews.java`
11. `src/main/java/com/ktown4u/capybara/application/PagedReviewComments.java`
12. `src/main/java/com/ktown4u/capybara/application/GetContentComment.java`

### 신규 생성
1. `src/test/java/com/ktown4u/capybara/masking/MaskingLibraryMigrationTest.java`
2. `src/test/java/com/ktown4u/capybara/masking/MaskingHeaderControlTest.java`
3. `src/test/java/com/ktown4u/capybara/masking/GraphQLMaskingTest.java`
4. `src/test/resources/masking-api-test.http`

---

## 롤백 전략

### 빌드 실패 시
- CodeArtifact repository 설정 제거
- mavenLocal()에 로컬 빌드된 라이브러리 사용

### 마스킹 오류 시
```yaml
# application.yml
masking:
  header-based: false  # MaskingFilter 비활성화
```

### Git 롤백
```bash
git revert <commit-hash>
```

---

## Uncertainty Map

### 확실한 부분
- ktown4u-masking 라이브러리 기능 및 사용법
- capybara 마스킹 적용 대상 파일 목록
- TDD 테스트 전략

### 확인 필요
- CI/CD 파이프라인의 CodeArtifact 토큰 갱신 방식
- 기존 MaskerTest.kt와의 정합성
