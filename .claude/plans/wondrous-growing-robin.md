# Capybara ktown4u-masking 문서 업데이트 계획

## 배경

Capybara 저장소에서 ktown4u-masking 라이브러리 사용 방식이 변경되었으며, 기존 문서를 실제 구현에 맞게 업데이트해야 합니다.

## Capybara Git 변경사항 요약

| 날짜 | 커밋 | 변경 내용 |
|-----|------|----------|
| 2026-01-08 | d49e7e29 | 프로덕션 마스킹 비활성화 (`masking.enabled: false`) |
| 2026-01-02 | 5e8eafde | 라이브러리 v1.0.1.3 → v1.1.1 업그레이드 |
| 2026-01-02 | c01df4a | **DB 수준 마스킹 제거** (@Masked, JpaMaskingAutoConfiguration 삭제) |
| 2025-12-30 | 6dcf2c35 | ktown4u-masking 라이브러리 최초 적용 |

### 현재 구현 방식
- **Application 레벨 명시적 마스킹**: DTO에서 `Masker.maskUserId()`, `Masker.maskName()` 직접 호출
- **withMaskedUserId() 패턴**: DTO에 마스킹 메서드 제공
- 프로덕션: `masking.enabled: false` / 개발: `masking.enabled: true`

### 삭제된 구성요소
- `@Masked` 어노테이션
- `JpaMaskingAutoConfiguration`
- `MaskingPostLoadEventListener`
- properties의 `columns` 설정

---

## 문서 업데이트 계획

### 1. `masking-implementation-plan.md` (우선순위 1)
**경로**: `/docs/isms-p/private-fields/masking-implementation-plan.md`

#### 변경사항
1. **"핵심 결정사항" 섹션** - 프로젝트별 구현 방식 분리 추가
2. **"대상 프로젝트" 테이블** - Capybara를 "조사 필요" → "구현 완료"로 이동
3. **신규 섹션 추가**: "Capybara 구현 상세" (커밋 이력, 현재 패턴, 환경별 설정)
4. **체크리스트** - Capybara 관련 항목 완료 처리

### 2. `masking-encryption-plan.md` (우선순위 2)
**경로**: `/docs/isms-p/private-fields/masking-encryption-plan.md`

#### 변경사항
1. **"Capybara (JPA 기반)" 섹션** 전면 재작성
   - "기존 Masker.java 패턴 유지 + 누락 필드 보완" → "ktown4u-masking 라이브러리 사용 완료"
2. **"보완 필요 사항" 테이블** 삭제 또는 완료 상태로 변경
3. **DB 수준 마스킹 폐기 이유** 추가

### 3. `capybara.md` (우선순위 3)
**경로**: `/docs/isms-p/private-fields/capybara.md`

#### 변경사항
1. **"권장사항" → "구현 현황"**으로 섹션 변경
2. **마스킹 구현 완료 테이블** 추가 (필드별 적용 상태)
3. **"시급한 조치" → "구현 완료 항목 / 미완료 항목"**으로 재구성

### 4. `isms-p-data-security-plan.md` (우선순위 4)
**경로**: `/docs/isms-p/isms-p-data-security-plan.md`

#### 변경사항
1. **"어노테이션 기반 필드 마킹" 섹션** - Capybara에서 폐기됨을 명시
2. **실제 구현 패턴 추가** - Application 레벨 명시적 마스킹 코드 예시
3. **"예상 작업량"** - Capybara 실제 소요 시간 반영

### 5. `field-based-masking-approach.md` (우선순위 5)
**경로**: `/docs/isms-p/private-fields/field-based-masking-approach.md`

#### 변경사항
1. **Capybara 실제 구현 결과** 섹션 추가
2. **선택된 접근법 및 채택 이유** 추가
3. **다른 프로젝트 적용 시 가이드** 추가

---

## 신규 문서 (확정)

### `capybara-masking-implementation.md`
**경로**: `/docs/isms-p/private-fields/capybara-masking-implementation.md`

Capybara 마스킹 구현의 상세 가이드 및 레퍼런스 문서

#### 포함 내용
- 구현 이력 (커밋 히스토리)
- 코드 패턴 (DTO 마스킹 메서드, 환경별 설정)
- 적용 파일 목록
- 삭제된 구성요소 (@Masked, JpaMaskingAutoConfiguration 등)
- 다른 프로젝트 적용 가이드

---

## 다른 프로젝트 적용 시 참고 패턴

```java
// 1. 라이브러리 의존성
implementation 'com.ktown4u:ktown4u-masking:1.1.1'

// 2. application.yml
masking:
  enabled: true  # 환경별 제어

// 3. DTO 마스킹 메서드 패턴
public ReviewDto withMaskedUserId() {
    return new ReviewDto(
        id,
        Masker.maskUserId(userId),
        Masker.maskName(username),
        ...
    );
}
```

### 프로젝트 특성별 권장 방식
| 프로젝트 특성 | 권장 방식 |
|-------------|----------|
| Map 반환 (레거시) | 필드명 기반 자동 마스킹 |
| DTO 반환 (모던) | Application 레벨 명시적 마스킹 |
| 본인/타인 구분 필요 | Application 레벨 명시적 마스킹 |

---

## 검증 방법

1. 각 문서 업데이트 후 내용 일관성 확인
2. 관련 문서 간 링크 연결 확인
3. 최종 수정일 업데이트

---

## Uncertainty Map

### 확인됨
- 프로덕션에서 `masking.enabled: false`는 **임시 조치** (향후 활성화 예정)

### 단순화
- 라이브러리 내부 구현 상세는 라이브러리 문서 참조 권장
