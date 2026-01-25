# ktown4u-masking 문서 재검토 및 수정 계획

> 상태: Phase 2 완료

## 배경

### 1. ktown4u-masking 라이브러리의 주요 변경 (c01df4a 커밋, 2025-01-02)

**제거된 기능 (3,994줄 삭제):**
- `@Masked` Annotation 기반 자동 마스킹
- JPA `PostLoadEventListener` (DB 로드 시 자동 마스킹)
- JPA Converter (`AbstractMaskingConverter`)
- MyBatis Interceptor (`MaskingInterceptor`)
- MyBatis TypeHandler (`AbstractMaskingTypeHandler`)
- Jackson Module (`MaskingModule`)
- `MaskingProperties` 설정 파일 기반 구성

**남아있는 기능 (직접 호출 방식):**
```java
// Masker.java의 8가지 정적 메서드
Masker.maskName("홍길동")           // → "홍*동"
Masker.maskUserId("username01")     // → "use*******"
Masker.maskEmail("user@example.com") // → "us**@example.com"
Masker.maskPhone("010-1234-5678")   // → "010-****-5678"
Masker.maskAddress("서울시 강남구...") // → "서울시 강남구 ***"
Masker.maskSsn("901231-1234567")    // → "901231-*******"
Masker.maskAccountNo("1234567890123") // → "1234*****0123"
Masker.maskPassNo("P123456789012")  // → "P1234********"

// MaskingConfig로 활성화/비활성화 제어
MaskingConfig.setEnabled(true/false);

// 암호화/복호화 (양방향)
Encryptor/Decryptor (AES-256-CBC)
```

### 2. capybara 프로젝트의 "직접 호출" 구현 패턴

```java
// DTO에서 마스킹 메서드 제공
public record UserDto(Long userNo, String userId, String username) {
    public UserDto withMaskedUserId() {
        return new UserDto(
                userNo,
                Masker.maskUserId(userId),
                Masker.maskName(username)
        );
    }
}

// 응답 생성 시점에 직접 호출
static CreateResponse of(final Review review) {
    return new CreateResponse(
            Masker.maskUserId(review.userId()),
            Masker.maskName(review.username()),
            // ...
    );
}
```

---

## 문서 분석 및 문제점

### 발견된 문서 (6개)
1. `masking-implementation-plan.md` - 전체 마스킹 구현 계획
2. `field-based-masking-approach.md` - 필드명 기반 접근법 의사결정
3. `masking-encryption-plan.md` - Mercury/Capybara 마스킹 적용 방식
4. `ktown4u-java.md` - 개인정보 보안 점검 보고서
5. `ktown4u-java-native-jdbc-analysis.md` - Native JDBC 분석
6. `ktown4u-web-pentest-2025.md` - 웹 모의해킹 결과

### 핵심 문제: 문서 간 불일치

| 문서 | 설명하는 방식 | 실제 구현 |
|------|-------------|---------|
| masking-implementation-plan.md | ResponseBodyAdvice + 필드명 기반 자동 마스킹 | ❌ 미구현 |
| masking-encryption-plan.md | JPA Converter + MyBatis TypeHandler | ❌ 제거됨 |
| capybara (실제 코드) | Masker.maskXxx() 직접 호출 | ✅ 현재 방식 |

**결론 (사용자 확인됨):**
- **"직접 호출 방식"이 표준으로 확정됨** = `Masker.maskXxx()` 정적 메서드를 서비스/DTO 레이어에서 직접 호출
- JPA/MyBatis/Jackson 자동 마스킹은 모두 제거됨
- ResponseBodyAdvice 방식은 폐기됨 (향후 도입 계획 없음)

---

## 수정 대상 문서

### 1. masking-encryption-plan.md (주요 수정 필요)

**수정 내용:**
- [ ] JPA Converter 예시 코드 제거 (`SsnConverter`, `@Convert` 어노테이션)
- [ ] MyBatis TypeHandler 예시 코드 제거 (`SsnTypeHandler`, `typeHandler` 설정)
- [ ] Entity 적용 예시 제거 (`@Convert(converter = SsnConverter.class)`)
- [ ] "직접 호출 방식"으로 예시 코드 업데이트
- [ ] 암호화(양방향)와 마스킹(단방향)의 적용 방식 명확화

### 2. masking-implementation-plan.md (주요 수정)

**수정 내용:**
- [ ] "ResponseBodyAdvice + 필드명 기반 자동 마스킹" 계획 내용 **완전 제거**
- [ ] Phase 1의 라이브러리 구조에서 미구현 컴포넌트 **완전 제거**:
  - `MaskingResponseBodyAdvice` 제거
  - `MapMasker` 제거
  - `MaskingFieldRegistry` 제거
  - `strategy/` 패키지 (NameMaskingStrategy 등) 제거
  - `MaskingService` 인터페이스 제거
- [ ] 현재 ktown4u-masking의 실제 구조(Masker.java, MaskingConfig.java 등)만 반영
- [ ] "직접 호출 방식"이 표준임을 명시

### 3. field-based-masking-approach.md (제거)

**제거 사유:**
- 내용이 fields.md, masking-implementation-plan.md와 중복
- "JSON 직렬화 + 필드명 기반 자동 마스킹"을 "선택됨"으로 표시하지만 실제 구현되지 않음
- 현재 표준("직접 호출 방식")과 충돌하여 오해 유발 가능

**조치:**
- [ ] 파일 삭제 또는 `_archived/` 폴더로 이동

---

## 수정 계획

### Phase 1: masking-encryption-plan.md 수정

1. **제거할 섹션:**
   - Mercury JPA Converter 예시
   - Mercury MyBatis TypeHandler 예시
   - Entity/Mapper 적용 예시

2. **추가/수정할 섹션:**
   - "직접 호출 방식" 구현 가이드
   - capybara 패턴 예시 (`withMaskedXxx()` 메서드)
   - 마스킹 적용 위치 가이드 (서비스 레이어 vs DTO 레이어)

3. **유지할 섹션:**
   - 암호화 대상 필드 (SSN, PASS_NO, ACCT_NO)
   - 마스킹 대상 필드 목록
   - 망분리 환경 분기 로직 (단, 구현 방식 변경)

### Phase 2: masking-implementation-plan.md 수정

1. **제거할 섹션 (미구현된 내용):**
   - ResponseBodyAdvice 관련 모든 내용
   - 필드명 기반 자동 마스킹 로직
   - `MaskingService`, `FieldNameBasedMaskingService` 인터페이스/구현체
   - `strategy/` 패키지 (각종 MaskingStrategy 클래스들)
   - `MaskingResponseBodyAdvice`, `MapMasker`
   - `MaskingFieldRegistry`, `MaskingProperties`

2. **유지/업데이트할 섹션:**
   - 마스킹 대상 필드 목록 (17개)
   - 마스킹 규칙 테이블 (이름, 이메일, 전화번호 등)
   - 프로젝트별 적용 대상 (ktown4u-java, mercury, gms-java-api 등)

3. **추가할 섹션:**
   - "직접 호출 방식" 표준 패턴 (capybara 예시)
   - 현재 ktown4u-masking 라이브러리 구조 (실제 구현된 것만)
   - 각 프로젝트에서 마스킹 적용해야 할 구체적인 위치

### Phase 3: 로그 마스킹 조사 및 가이드 추가

**조사 대상 (사용자 확인됨):**
1. capybara 프로젝트 - 로그에서 민감정보 노출 가능성 조사
2. mercury 프로젝트 - 로그에서 민감정보 노출 가능성 조사

**조사 항목:**
- `@Slf4j` / `Logger` 사용 위치에서 민감 필드 출력 여부
- Exception 스택트레이스에 민감정보 포함 여부
- GraphQL 요청/응답 로깅에서 민감정보 노출 여부
- Spring Security 인증 로깅에서 사용자 정보 노출 여부

**산출물:**
- 로그 마스킹 가이드라인 문서 추가
- 필요시 로그 마스킹 적용 위치 목록

---

## 파일 변경 목록

| 파일 | 변경 유형 | 우선순위 |
|------|----------|---------|
| `docs/isms-p/private-fields/masking-encryption-plan.md` | 주요 수정 (JPA/MyBatis 예시 제거) | 높음 |
| `docs/isms-p/private-fields/masking-implementation-plan.md` | 주요 수정 (미구현 내용 완전 제거) | 높음 |
| `docs/isms-p/private-fields/field-based-masking-approach.md` | **삭제** (중복 + 오해 유발) | 높음 |

---

## 검증 방법

1. 수정된 문서가 ktown4u-masking의 현재 구현과 일치하는지 확인
2. capybara의 "직접 호출 방식" 패턴이 문서에 정확히 반영되었는지 확인
3. 제거된 기능(JPA Converter, MyBatis TypeHandler 등)에 대한 언급이 삭제되었는지 확인
4. **미구현된 기능(ResponseBodyAdvice, MapMasker, MaskingStrategy 등)에 대한 언급이 완전히 삭제되었는지 확인**

---

## Uncertainty Map

| 항목 | 불확실성 수준 | 확인 필요 사항 |
|------|-------------|--------------|
| 로그 마스킹 실제 노출 케이스 | 중간 | capybara, mercury 조사 후 구체화 예정 |
| 암호화 필드 처리 | 낮음 | Encryptor/Decryptor 사용 방식은 명확함 |
| 다른 프로젝트 적용 | 중간 | gms-java-api, thomas 등은 별도 조사 필요 |
| field-based-masking-approach.md 수정 범위 | 낮음 | 폐기된 접근법임을 명시하는 정도로 충분할 것으로 예상 |

---

## Phase 1 완료 (2026-01-12)

### 완료된 작업

| 작업 | 상태 |
|------|------|
| `field-based-masking-approach.md` 삭제 | ✅ 완료 |
| `masking-encryption-plan.md` 수정 (JPA/MyBatis 예시 제거) | ✅ 완료 |
| `masking-implementation-plan.md` 수정 (미구현 내용 제거) | ✅ 완료 |
| capybara, mercury 로그 마스킹 조사 | ✅ 완료 |
| `log-masking-guideline.md` 생성 | ✅ 완료 |

---

## Phase 2: 문서 역할 분리 (완료: 2026-01-12)

### 완료된 작업

| 작업 | 상태 |
|------|------|
| `masking-encryption-plan.md` 고유 내용 분석 | ✅ 완료 |
| `masking-implementation-plan.md`에 "확정된 정책" 섹션 추가 | ✅ 완료 |
| `masking-implementation-plan.md`에서 masking-encryption-plan.md 링크 제거 | ✅ 완료 |
| `masking-encryption-plan.md` 파일 삭제 | ✅ 완료 |

### 최종 문서 구조

```
docs/isms-p/private-fields/
├── masking-implementation-plan.md    # 전체 마스킹 전략/계획 (통합 완료)
├── fields.md                         # 마스킹 대상 필드 목록
├── log-masking-guideline.md          # 로그 마스킹 가이드라인
└── ktown4u-java-native-jdbc-analysis.md  # Native JDBC 분석 문서
```

### 주요 변경사항

1. **masking-encryption-plan.md 삭제**
   - `masking-implementation-plan.md`와 90% 이상 중복
   - 고유 내용("확정된 정책" 4가지)은 통합 완료

2. **masking-implementation-plan.md 보완**
   - "확정된 정책" 섹션 추가 (4가지 정책)
   - 관련 문서 링크에서 삭제된 파일 제거
   - `log-masking-guideline.md` 링크 추가
