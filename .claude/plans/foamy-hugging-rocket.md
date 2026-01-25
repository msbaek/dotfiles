# ktown4u-masking 문서 업데이트 계획

## 배경

ktown4u-masking 라이브러리가 **직접 호출 방식만 지원**하도록 단순화되었습니다.

### 라이브러리 변경 이력 (79dc2e9, d98a106 커밋)
- ❌ 제거됨: ResponseBodyAdvice, 필드명 기반 자동 마스킹
- ❌ 제거됨: @Masked 어노테이션, JpaMaskingAutoConfiguration
- ❌ 제거됨: Spring Profile 기반 dmz 프로필 체크 로직
- ✅ 유지됨: `Masker.maskXxx()` 직접 호출 방식만 지원

### 핵심 결정
**모든 프로젝트가 동일한 방식(Application 레벨 명시적 마스킹)으로 구현 예정**
- capybara (완료)
- mercury, ktown4u-java, gms-java-api (예정) - 모두 동일 방식

---

## 문서별 수정 필요 사항

### 1. `masking-implementation-plan.md` (우선순위 1)
**경로**: `/docs/isms-p/private-fields/masking-implementation-plan.md`

| 섹션 | 현재 내용 | 수정 내용 |
|-----|---------|----------|
| 핵심 결정사항 | "JSON 직렬화 + 필드명 기반 자동 마스킹" | **"Application 레벨 명시적 마스킹"으로 변경** |
| 프로젝트별 구현 방식 테이블 | ktown4u-java: ResponseBodyAdvice + 필드명 기반 | **모든 프로젝트: Application 레벨 명시적 마스킹** |
| Phase 1: 공통 라이브러리 | ResponseBodyAdvice, MapMasker, MaskingFieldRegistry 등 | **단순화 - Masker 클래스만 설명** |
| Phase 2: 프로젝트별 적용 | 프로젝트마다 다른 방식 | **모든 프로젝트 동일 방식 (withMaskedXxx 패턴)** |
| 구현 순서 체크리스트 | ResponseBodyAdvice, MapMasker 등 | **삭제 또는 단순화** |

### 2. `masking-encryption-plan.md` (우선순위 2)
**경로**: `/docs/isms-p/private-fields/masking-encryption-plan.md`

| 섹션 | 현재 내용 | 수정 내용 |
|-----|---------|----------|
| Mercury (JPA + MyBatis 혼합) | JPA Converter, MyBatis TypeHandler 방식 상세 설명 | **명시적 마스킹 방식으로 변경** (Capybara와 동일) |
| 구현 구조 | security/converter/, handler/ 디렉토리 구조 | **단순화 - Masker 직접 호출 패턴만** |
| Phase 1: Mercury | Converter/TypeHandler 구현 체크리스트 | **Capybara와 동일한 패턴 적용으로 변경** |

### 3. `field-based-masking-approach.md` (우선순위 3)
**경로**: `/docs/isms-p/private-fields/field-based-masking-approach.md`

| 섹션 | 현재 내용 | 수정 내용 |
|-----|---------|----------|
| 문서 상태 | "확정 (Capybara는 다른 방식 채택)" | **"폐기됨 - 모든 프로젝트 명시적 마스킹 채택"** |
| 프로젝트 특성별 권장 방식 | Map 반환: 필드명 기반 / DTO 반환: 명시적 | **모든 경우: Application 레벨 명시적 마스킹** |
| 선택한 접근법 섹션 | 필드명 기반 자동 마스킹 장점 강조 | **역사적 참고용으로 유지하되, 현재는 폐기됨 명시** |

### 4. `capybara-masking-implementation.md` (우선순위 4)
**경로**: `/docs/isms-p/private-fields/capybara-masking-implementation.md`

| 섹션 | 현재 내용 | 수정 내용 |
|-----|---------|----------|
| 프로젝트 특성별 권장 방식 | Map 반환: 필드명 기반 권장 | **모두 "명시적 마스킹" 권장으로 통일** |
| Uncertainty Map | "다른 프로젝트 동일 패턴 적용 여부 미확인" | **확정됨 - 모든 프로젝트 동일 패턴 적용** |

### 5. `isms-p-data-security-plan.md` (우선순위 5) - 대폭 축소
**경로**: `/docs/isms-p/isms-p-data-security-plan.md`

**결정**: 마스킹 직접 호출 방식만 남기고 나머지 모두 삭제

| 삭제 대상 섹션 |
|--------------|
| 어노테이션 기반 필드 마킹 (@Masked, @Encrypted, @Sensitive) |
| Jackson Serializer 커스터마이징 (BeanSerializerModifier 등) |
| MyBatis TypeHandler (EncryptedStringTypeHandler 등) |
| JSP Tag Library |
| 로깅 마스킹 (MaskingPatternLayout) |
| 암호화 관련 (Encryptor/Decryptor, AES-256) |
| 8.1~8.7 상세 구현 예시 전체 |
| 9. MyBatis TypeHandler 섹션 전체 |
| 10. 로깅 마스킹 섹션 전체 |

**유지할 내용**:
- 개요 (아키텍처 설명 단순화)
- Application 레벨 명시적 마스킹 패턴 (Capybara 방식)
- Masker 유틸리티 메서드 설명
- 다른 프로젝트 적용 가이드

---

## 공통 적용 사항

### 변경될 코드 패턴 (모든 프로젝트 동일)

```java
// 1. 라이브러리 의존성
implementation 'com.ktown4u:ktown4u-masking:1.1.1'

// 2. application.yml
masking:
  enabled: true  # 환경별 제어

// 3. DTO 마스킹 메서드 패턴
public YourDto withMaskedUserInfo() {
    return new YourDto(
        id,
        Masker.maskUserId(userId),
        Masker.maskName(username),
        // ... 기타 필드
    );
}

// 4. 서비스에서 호출
return repository.findAll()
    .map(YourDto::withMaskedUserInfo);
```

### 삭제할 내용 목록

1. **ResponseBodyAdvice 관련**: MaskingResponseBodyAdvice, 필드명 기반 자동 감지
2. **JPA 관련**: @Masked 어노테이션, JpaMaskingAutoConfiguration, MaskingPostLoadEventListener
3. **JPA Converter 관련**: SsnConverter, NameMaskingConverter 등
4. **MyBatis TypeHandler 관련**: SsnTypeHandler, EncryptedStringTypeHandler 등
5. **Jackson 관련**: MaskingSerializer, MaskingBeanSerializerModifier, Jackson Module 설정
6. **설정 관련**: `columns` 설정, URL 패턴 기반 적용 설정

---

## 수정 파일 목록

| 파일 | 예상 변경량 | 비고 |
|-----|-----------|------|
| `masking-implementation-plan.md` | 대폭 수정 | 핵심 결정사항 변경 |
| `masking-encryption-plan.md` | 대폭 수정 | Mercury 섹션 전면 재작성 |
| `field-based-masking-approach.md` | 중간 수정 | 상태 변경 + 권장 방식 통일 |
| `capybara-masking-implementation.md` | 소폭 수정 | 권장 방식 테이블 수정 |
| `isms-p-data-security-plan.md` | 대폭 수정 | 폐기된 방식 정리 |

---

## 검증 방법

1. 각 문서 내 "ResponseBodyAdvice", "필드명 기반", "자동 마스킹" 키워드 검색하여 제거/수정 확인
2. 모든 문서에서 권장 방식이 "Application 레벨 명시적 마스킹"으로 통일되었는지 확인
3. 관련 문서 간 링크 연결 확인
4. 최종 수정일 업데이트

---

## Uncertainty Map

### 확인됨
- 모든 프로젝트가 동일한 방식(명시적 마스킹)으로 구현 예정
- ktown4u-masking 라이브러리에서 직접 호출 외 기능 모두 제거됨

### 확인 필요
- `isms-p-data-security-plan.md`의 JSP Tag Library, 로깅 마스킹 섹션 유지 여부
- 암호화(Encryptor/Decryptor) 관련 내용 유지 여부 (마스킹과 별개 기능)
