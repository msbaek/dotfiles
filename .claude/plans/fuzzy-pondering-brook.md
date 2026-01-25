# ktown4u-masking Jackson MaskingModule 적용 계획

## 개요
capybara 프로젝트에 ktown4u-masking 라이브러리를 **Jackson MaskingModule** 방식으로 적용하여, DTO에 `@Masked` 어노테이션만 추가하면 JSON 직렬화 시 자동으로 마스킹되도록 변경

## 현황
- ktown4u-masking v1.0.1.3 이미 적용됨
- 현재 방식: `withMaskedUserId()` 메서드로 수동 마스킹
- 마스킹 필드: `userId` (USER_ID), `username`/`userName` (NAME)

---

## 구현 단계

### 1단계: MaskingModule Bean 등록
**파일**: `src/main/java/com/ktown4u/capybara/configurations/JacksonMaskingConfiguration.java` (신규)

```java
@Configuration
public class JacksonMaskingConfiguration {
    @Bean
    public MaskingModule maskingModule() {
        return new MaskingModule();
    }
}
```

---

### 2단계: DTO에 @Masked 어노테이션 적용

#### 2.1 ReviewDto
**파일**: `src/main/java/com/ktown4u/capybara/projections/ReviewDto.java`
```java
public record ReviewDto(
        ...
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String username,
        ...
) {
    // withMaskedUserId() 메서드 제거
}
```

#### 2.2 ReviewCommentDto
**파일**: `src/main/java/com/ktown4u/capybara/projections/ReviewCommentDto.java`
```java
public record ReviewCommentDto(
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String userName,
        ...
        @Masked(MaskingType.USER_ID) String fullUserId  // 원본 userId도 마스킹
) {
    // withMaskedUserId() 메서드 제거
}
```

#### 2.3 ContentItemCommentDto
**파일**: `src/main/java/com/ktown4u/capybara/projections/ContentItemCommentDto.java`
```java
public record ContentItemCommentDto(
        ...
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String userName,
        ...
) {
    // withMaskedUserId() 메서드 제거
}
```

#### 2.4 UserDto
**파일**: `src/main/java/com/ktown4u/capybara/projections/UserDto.java`
```java
public record UserDto(
        Long userNo,
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String username
) {
    // withMaskedUserId() 메서드 제거
}
```

#### 2.5 EventCommentDto (구조 변경 필요)
**파일**: `src/main/java/com/ktown4u/capybara/projections/EventCommentDto.java`

현재 User 엔티티를 직접 참조 → 개별 필드로 분리:
```java
public record EventCommentDto(
        Long id,
        String content,
        LocalDateTime createdAt,
        Long userNo,
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String username,
        Long likeCount,
        CommentStatus status
) {}
```

**관련 변경**: `EventCommentDao` 쿼리에서 User 대신 userId, username 직접 조회

---

### 3단계: 내부 Response Record에 @Masked 적용

#### CreateReview.CreateResponse
**파일**: `src/main/java/com/ktown4u/capybara/CreateReview.java`
```java
record CreateResponse(
        ...
        @Masked(MaskingType.USER_ID) String userId,
        @Masked(MaskingType.NAME) String username,
        ...
) {}
```

#### PagedEventComments.EventCommentResponse
**파일**: `src/main/java/com/ktown4u/capybara/PagedEventComments.java`
```java
record EventCommentResponse(
        ...
        @Masked(MaskingType.USER_ID) String fullUserId,
        @Masked(MaskingType.USER_ID) String userId
) {}
```

#### CreateEventComment.CreateEventCommentResponse
**파일**: `src/main/java/com/ktown4u/capybara/CreateEventComment.java`
```java
record CreateEventCommentResponse(
        ...
        @Masked(MaskingType.USER_ID) String userId
) {}
```

---

### 4단계: ContentComment 도메인 객체 수정
**파일**: `src/main/java/com/ktown4u/capybara/domain/ContentComment.java`
```java
@Getter
public class ContentComment {
    @Masked(MaskingType.USER_ID)
    private final String userId;

    @Masked(MaskingType.NAME)
    private final String userName;

    // of() 메서드에서 Masker.maskUserId() 호출 제거
}
```

---

### 5단계: 수동 마스킹 코드 제거

| 파일 | 변경 내용 |
|------|----------|
| `PagedReviews.java` | `.map(ReviewDto::withMaskedUserId)` 제거 (라인 70, 80, 178) |
| `PagedReviewComments.java` | `.map(ReviewCommentDto::withMaskedUserId)` 제거 (라인 53, 64) |
| `CreateReview.java` | `Masker.maskUserId()`, `Masker.maskName()` 호출 제거 |
| `CreateEventComment.java` | `Masker.maskUserId()` 호출 제거 |
| `PagedEventComments.java` | `Masker.maskUserId()` 호출 제거 |
| `ContentComment.java` | `of()` 메서드에서 `Masker.maskUserId()` 제거 |

---

### 6단계: 테스트 작성
**파일**: `src/test/java/com/ktown4u/capybara/MaskingModuleIntegrationTest.java` (신규)

- ReviewDto 마스킹 테스트
- UserDto 마스킹 테스트
- record 타입 @Masked 어노테이션 동작 확인

---

## 수정 파일 목록

### 신규 파일
- `src/main/java/com/ktown4u/capybara/configurations/JacksonMaskingConfiguration.java`
- `src/test/java/com/ktown4u/capybara/MaskingModuleIntegrationTest.java`

### 수정 파일 (DTO)
- `src/main/java/com/ktown4u/capybara/projections/ReviewDto.java`
- `src/main/java/com/ktown4u/capybara/projections/ReviewCommentDto.java`
- `src/main/java/com/ktown4u/capybara/projections/ContentItemCommentDto.java`
- `src/main/java/com/ktown4u/capybara/projections/UserDto.java`
- `src/main/java/com/ktown4u/capybara/projections/EventCommentDto.java`
- `src/main/java/com/ktown4u/capybara/domain/ContentComment.java`

### 수정 파일 (수동 마스킹 제거)
- `src/main/java/com/ktown4u/capybara/PagedReviews.java`
- `src/main/java/com/ktown4u/capybara/PagedReviewComments.java`
- `src/main/java/com/ktown4u/capybara/CreateReview.java`
- `src/main/java/com/ktown4u/capybara/CreateEventComment.java`
- `src/main/java/com/ktown4u/capybara/PagedEventComments.java`
- `src/main/java/com/ktown4u/capybara/GetContentComment.java` (ContentComment 사용 시)

### 수정 파일 (EventCommentDto 구조 변경 관련)
- `src/main/java/com/ktown4u/capybara/projections/EventCommentDao.java` (쿼리 수정)

---

## 주의사항

1. **관리자 API**: `reviewsForAdmin`, `commentsForAdminByReviewId` 등도 자동 마스킹됨 (사용자 결정대로)
2. **fullUserId 필드**: 원본 userId 저장 용도였으나, 마스킹 적용으로 변경됨
3. **캐시**: `@Cacheable` 적용된 메서드의 캐시 무효화 필요할 수 있음
4. **역직렬화**: 마스킹은 직렬화(응답)에만 적용, 역직렬화(요청)는 원본 그대로

---

## Uncertainty Map

- **EventCommentDao 쿼리 변경 범위**: User 엔티티 대신 개별 필드 조회로 변경 시 영향 범위 확인 필요
- **캐시 전략**: Redis 캐시에 저장된 데이터 상태 검토 필요
