# HTTP 헤더 기반 조건부 마스킹 구현 계획서

> 작성일: 2026-01-22
> 목적: `X-Skip-Masking: true` 헤더가 있는 DMZ 요청은 마스킹 해제
> 구현 위치: ktown4u-masking 라이브러리
> Spring Boot: 3.x (Jakarta Servlet)

---

## 1. 배경 및 목적

### 1.1 배경
- 현재 마스킹은 `masking.enabled` 프로퍼티로 **전역 제어**만 가능
- **기본값은 마스킹 적용** (개인정보 보호)
- DMZ 환경에서 들어오는 요청은 마스킹 해제 필요 (내부망에서 원본 데이터 필요)
- HTTP 헤더 `X-Skip-Masking: true`로 DMZ 요청 식별

### 1.2 목적
- **요청별 동적 마스킹 제어** 구현
- 기본값: 마스킹 적용 (보안 우선)
- DMZ 요청만 마스킹 해제
- 기존 API 호환성 유지 (하위 호환)
- 사용 서비스(capybara, mercury 등)에서 최소 설정으로 적용 가능

---

## 2. 현재 아키텍처 분석

### 2.1 현재 구조
```
application.yml (masking.enabled: true/false)
       ↓
MaskingAutoConfiguration (애플리케이션 시작 시 1회)
       ↓
MaskingConfig (전역 static volatile boolean)
       ↓
Masker.maskXxx() 메서드들 → if (!MaskingConfig.isEnabled()) return input;
```

### 2.2 현재 코드 (MaskingConfig.java)
```java
public class MaskingConfig {
    private static volatile boolean enabled = true;

    public static boolean isEnabled() { return enabled; }
    public static void setEnabled(boolean enabled) { MaskingConfig.enabled = enabled; }
}
```

### 2.3 현재 코드 (Masker.java 패턴)
```java
public static String maskName(String input) {
    if (input == null) return null;
    if (!MaskingConfig.isEnabled()) return input;  // ← 전역 상태만 체크
    // 마스킹 로직...
}
```

### 2.4 문제점
- **전역 상태**: 모든 요청이 동일한 마스킹 정책 공유
- **HTTP 컨텍스트 없음**: 요청별 헤더 체크 불가
- **동적 제어 불가**: 런타임에 요청 단위로 on/off 불가

---

## 3. 설계 방안

### 3.1 선택: ThreadLocal 기반 요청 컨텍스트

```
HTTP 요청 (x-dmz: y 헤더 포함)
       ↓
MaskingFilter (라이브러리 제공)
       ↓
ThreadLocal에 마스킹 활성화 여부 저장
       ↓
Masker.maskXxx() → ThreadLocal 값 우선 확인
       ↓
응답 후 ThreadLocal 정리
```

### 3.2 설계 원칙
1. **하위 호환성**: 기존 `masking.enabled` 프로퍼티 동작 유지
2. **우선순위**: ThreadLocal 값 > 전역 설정
3. **기본값**: ThreadLocal 미설정 시 전역 설정 따름
4. **자원 정리**: 요청 완료 후 ThreadLocal 반드시 정리

### 3.3 마스킹 활성화 로직 (보안 우선 설계)
```
기본값 (헤더 없음) → 마스킹 O (보안 우선)
X-Skip-Masking: true → 마스킹 X (DMZ 요청, 원본 데이터 반환)
X-Skip-Masking: false 또는 다른 값 → 마스킹 O
```

### 3.4 헤더 설계 이유
| 항목 | 선택 | 이유 |
|------|------|------|
| 헤더명 | `X-Skip-Masking` | 마스킹 건너뛰기 의미 명확 |
| 헤더값 | `true` | true일 때만 마스킹 해제 |
| 기본값 | 마스킹 적용 | 보안 우선 (Secure by Default) |
| 대소문자 | case-insensitive | HTTP 헤더 표준 준수 |

---

## 4. 구현 계획

### 4.1 파일 구조 (신규/수정)

```
lib/src/main/java/com/ktown4u/masking/
├── MaskingConfig.java          # [수정] ThreadLocal 지원 추가
├── MaskingContext.java         # [신규] ThreadLocal 관리
├── Masker.java                 # [수정 불필요] MaskingConfig.isEnabled() 그대로 사용
└── filter/
    └── MaskingFilter.java      # [신규] HTTP 헤더 체크 + ThreadLocal 설정
```

### 4.2 구현 상세

#### 4.2.1 MaskingContext.java (신규)
```java
public class MaskingContext {
    private static final ThreadLocal<Boolean> REQUEST_MASKING_ENABLED = new ThreadLocal<>();

    public static void setEnabled(Boolean enabled) {
        REQUEST_MASKING_ENABLED.set(enabled);
    }

    public static Boolean isEnabled() {
        return REQUEST_MASKING_ENABLED.get();
    }

    public static void clear() {
        REQUEST_MASKING_ENABLED.remove();
    }
}
```

#### 4.2.2 MaskingConfig.java (수정)
```java
public class MaskingConfig {
    private static volatile boolean enabled = true;

    public static boolean isEnabled() {
        // ThreadLocal 값이 있으면 우선 적용
        Boolean requestEnabled = MaskingContext.isEnabled();
        if (requestEnabled != null) {
            return requestEnabled;
        }
        // 없으면 전역 설정 사용
        return enabled;
    }

    public static void setEnabled(boolean enabled) {
        MaskingConfig.enabled = enabled;
    }
}
```

#### 4.2.3 MaskingFilter.java (신규)
```java
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class MaskingFilter extends OncePerRequestFilter {

    private static final String SKIP_MASKING_HEADER = "X-Skip-Masking";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String headerValue = request.getHeader(SKIP_MASKING_HEADER);
            // 기본값: 마스킹 적용 (true)
            // X-Skip-Masking: true → 마스킹 해제 (false)
            boolean shouldMask = !"true".equalsIgnoreCase(headerValue);
            MaskingContext.setEnabled(shouldMask);

            filterChain.doFilter(request, response);
        } finally {
            MaskingContext.clear();  // 반드시 정리
        }
    }
}
```

#### 4.2.4 MaskingAutoConfiguration.java (수정)
```java
@Configuration
@ConditionalOnClass(MaskingConfig.class)
public class MaskingAutoConfiguration {

    public MaskingAutoConfiguration(@Value("${masking.enabled:true}") boolean enabled) {
        MaskingConfig.setEnabled(enabled);
    }

    @Bean
    @ConditionalOnWebApplication
    @ConditionalOnProperty(name = "masking.header-based", havingValue = "true", matchIfMissing = false)
    public MaskingFilter maskingFilter() {
        return new MaskingFilter();
    }
}
```

### 4.3 의존성 추가 (build.gradle)
```groovy
dependencies {
    // 기존
    compileOnly 'org.springframework.boot:spring-boot-starter'

    // 추가 (Filter 지원 - Spring Boot 3.x / Jakarta)
    compileOnly 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'jakarta.servlet:jakarta.servlet-api:6.0.0'
}
```

---

## 5. 사용 서비스 설정 (capybara, mercury 등)

### 5.1 application.yml 설정
```yaml
masking:
  enabled: true           # 전역 기본값 (기존)
  header-based: true      # 헤더 기반 제어 활성화 (신규)
```

### 5.2 동작 시나리오

| 요청 헤더 | masking.enabled | masking.header-based | 결과 | 설명 |
|-----------|-----------------|----------------------|------|------|
| (헤더 없음) | true | true | **마스킹 O** | 기본값 (보안 우선) |
| X-Skip-Masking: true | true | true | 마스킹 X | DMZ 요청 |
| X-Skip-Masking: false | true | true | **마스킹 O** | 명시적 마스킹 |
| X-Skip-Masking: true | false | true | 마스킹 X | 헤더 우선 |
| (any) | true | false | **마스킹 O** | 전역 설정 사용 |
| (any) | false | false | 마스킹 X | 전역 설정 사용 |

---

## 6. 테스트 계획

### 6.1 단위 테스트

#### MaskingContextTest.java
- ThreadLocal set/get/clear 동작 확인
- 멀티스레드 격리 확인

#### MaskingConfigTest.java
- ThreadLocal 값 우선순위 확인
- ThreadLocal 없을 때 전역 설정 사용 확인

#### MaskingFilterTest.java
- 헤더 없음 → MaskingContext.isEnabled() == true (기본값: 마스킹 O)
- X-Skip-Masking: true → MaskingContext.isEnabled() == false (마스킹 X)
- X-Skip-Masking: false → MaskingContext.isEnabled() == true (마스킹 O)
- finally에서 clear 호출 확인

### 6.2 통합 테스트

#### MaskingIntegrationTest.java
```java
@SpringBootTest
@AutoConfigureMockMvc
class MaskingIntegrationTest {

    @Test
    void 기본값_마스킹_적용() {
        // 헤더 없음 → 마스킹 O (보안 우선)
        mockMvc.perform(get("/api/user/1"))
            .andExpect(jsonPath("$.name").value("홍*동"));
    }

    @Test
    void DMZ_요청은_마스킹_해제() {
        // X-Skip-Masking: true → 마스킹 X
        mockMvc.perform(get("/api/user/1")
                .header("X-Skip-Masking", "true"))
            .andExpect(jsonPath("$.name").value("홍길동"));
    }
}
```

---

## 7. 검증 방법

### 7.1 로컬 테스트
```bash
# 기본값: 마스킹 적용 (헤더 없음)
curl http://localhost:8080/api/user/1
# 예상: {"name": "홍*동", "email": "ho**@example.com"}

# DMZ 요청: 마스킹 해제 (X-Skip-Masking: true)
curl -H "X-Skip-Masking: true" http://localhost:8080/api/user/1
# 예상: {"name": "홍길동", "email": "hong@example.com"}
```

### 7.2 테스트 실행
```bash
./gradlew test
```

---

## 8. 구현 순서 (TODO)

1. [ ] `MaskingContext.java` 생성 - ThreadLocal 관리 클래스
2. [ ] `MaskingConfig.java` 수정 - ThreadLocal 값 우선 체크
3. [ ] `MaskingFilter.java` 생성 - HTTP 헤더 체크 필터
4. [ ] `MaskingAutoConfiguration.java` 수정 - Filter Bean 등록
5. [ ] `build.gradle` 수정 - 의존성 추가
6. [ ] 단위 테스트 작성
7. [ ] 통합 테스트 작성
8. [ ] 문서 업데이트 (docs/MASKING-GUIDE.md)

---

## 9. 산출물

### 9.1 생성할 문서
- `docs/http-header-masking-plan.md` - 이 계획서

### 9.2 수정할 파일
- `lib/src/main/java/com/ktown4u/masking/MaskingConfig.java`
- `lib/src/main/java/com/ktown4u/masking/config/MaskingAutoConfiguration.java`
- `lib/build.gradle`
- `docs/MASKING-GUIDE.md`

### 9.3 신규 생성할 파일
- `lib/src/main/java/com/ktown4u/masking/MaskingContext.java`
- `lib/src/main/java/com/ktown4u/masking/filter/MaskingFilter.java`
- `lib/src/test/java/com/ktown4u/masking/MaskingContextTest.java`
- `lib/src/test/java/com/ktown4u/masking/filter/MaskingFilterTest.java`

---

## 10. Uncertainty Map

| 항목 | 확신도 | 비고 |
|------|--------|------|
| ThreadLocal 방식 적합성 | 높음 | Spring 표준 패턴 |
| Filter vs Interceptor 선택 | 높음 | Filter가 더 이른 시점에 동작 |
| 헤더명 `X-Skip-Masking` | ✅ 확정 | 마스킹 건너뛰기 의미 명확 |
| 헤더값 `true` | ✅ 확정 | Boolean 표준 |
| Spring Boot 버전 | ✅ 확정 | 3.x (Jakarta) |
| 비동기 요청 처리 (@Async) | 중간 | ThreadLocal 전파 필요할 수 있음 |

---

## 11. 확정 사항

| 항목 | 결정 | 이유 |
|------|------|------|
| 헤더명 | `X-Skip-Masking` | 마스킹 건너뛰기 의미 명확 |
| 헤더값 | `true` | Boolean 표준, case-insensitive |
| 기본 동작 | 마스킹 적용 | 보안 우선 (Secure by Default) |
| DMZ 요청 | 마스킹 해제 | 헤더 `true`일 때만 |
| Spring Boot | 3.x (Jakarta Servlet) | capybara, mercury 환경 |
