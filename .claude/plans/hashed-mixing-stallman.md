# Spring Profile 기반 마스킹 제어 계획

## 목표
Spring Profile을 통해 마스킹 적용 여부를 제어
- **dmz** 프로필 (망분리 환경): 마스킹 OFF (원본 그대로 반환)
- **기타 환경** (일반): 마스킹 ON

## 사용자 결정사항
- 망분리 환경 Profile 이름: `dmz`
- 구현 방식: **Static 유지 + 프로퍼티 참조**

---

## 구현 설계

### 핵심 아이디어
Masker의 static 메서드를 유지하면서, Spring ApplicationContext에서 프로퍼티를 읽어 전역 상태로 관리

### 클래스 구조

```
lib/src/main/java/com/ktown4u/masking/
├── Masker.java              # 기존 (수정)
├── MaskingType.java         # 기존 (유지)
├── MaskingConfig.java       # 신규 - 마스킹 활성화 상태 관리
└── config/
    └── MaskingAutoConfiguration.java  # 신규 - Spring Boot 자동 설정
```

---

## 구현 상세

### 1. MaskingConfig 클래스 (신규)
마스킹 활성화 상태를 관리하는 싱글톤 패턴 클래스

```java
// lib/src/main/java/com/ktown4u/masking/MaskingConfig.java
public class MaskingConfig {
    private static volatile boolean enabled = true;  // 기본값: 활성화

    public static boolean isEnabled() {
        return enabled;
    }

    public static void setEnabled(boolean enabled) {
        MaskingConfig.enabled = enabled;
    }
}
```

### 2. Masker.java 수정
모든 마스킹 메서드에서 MaskingConfig.isEnabled() 체크

```java
public static String maskName(String name) {
    if (name == null) return null;
    if (!MaskingConfig.isEnabled()) return name;  // 추가
    // 기존 마스킹 로직
}
```

### 3. MaskingAutoConfiguration 클래스 (신규)
Spring Boot 자동 설정으로 프로퍼티/프로필 기반 초기화

```java
// lib/src/main/java/com/ktown4u/masking/config/MaskingAutoConfiguration.java
@Configuration
@ConditionalOnClass(MaskingConfig.class)
public class MaskingAutoConfiguration {

    @PostConstruct
    public void configureMasking(
            @Value("${masking.enabled:true}") boolean enabled,
            Environment environment) {

        // dmz 프로필이면 마스킹 비활성화
        if (Arrays.asList(environment.getActiveProfiles()).contains("dmz")) {
            MaskingConfig.setEnabled(false);
        } else {
            MaskingConfig.setEnabled(enabled);
        }
    }
}
```

### 4. 자동 설정 등록
```
lib/src/main/resources/META-INF/spring/
    org.springframework.boot.autoconfigure.AutoConfiguration.imports
```
내용: `com.ktown4u.masking.config.MaskingAutoConfiguration`

---

## 프로퍼티 설정 예시

### application.yml (기본 - 마스킹 ON)
```yaml
masking:
  enabled: true
```

### application-dmz.yml (망분리 - 마스킹 OFF)
```yaml
masking:
  enabled: false
```

또는 프로필만으로 자동 제어 (프로퍼티 없이도 dmz면 OFF)

---

## 수정 대상 파일

| 파일 | 작업 |
|------|------|
| `Masker.java` | 각 메서드에 `MaskingConfig.isEnabled()` 체크 추가 |
| `MaskingConfig.java` | 신규 생성 |
| `config/MaskingAutoConfiguration.java` | 신규 생성 |
| `AutoConfiguration.imports` | MaskingAutoConfiguration 등록 |

---

## 테스트 계획

### 단위 테스트
- `MaskingConfig.setEnabled(false)` 시 Masker 메서드들이 원본 반환하는지

### 통합 테스트
- `@ActiveProfiles("dmz")` 설정 시 마스킹 비활성화 확인
- 기본 프로필 시 마스킹 활성화 확인

---

## Backlog Tasks

1. MaskingConfig 클래스 생성
2. Masker.java에 isEnabled() 체크 추가
3. MaskingAutoConfiguration 클래스 생성
4. AutoConfiguration.imports 설정
5. 테스트 코드 작성
6. 빌드 및 검증

---

## Uncertainty Map

### 확신도 높음
- MaskingConfig 싱글톤 패턴으로 전역 상태 관리
- Masker 각 메서드에 조건 추가

### 확신도 중간
- 멀티스레드 환경에서 volatile 키워드만으로 충분한지 (읽기 전용이므로 문제없을 것)
- Spring Boot가 없는 환경에서 기본값(true) 유지 여부

### 추가 확인 필요
- 라이브러리 사용처에서 Spring Boot 없이 사용하는 경우가 있는지
