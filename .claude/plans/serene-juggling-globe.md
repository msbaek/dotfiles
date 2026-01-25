# ktown4u-masking 라이브러리 적용 계획

## 목표
capybara 프로젝트에 ktown4u-masking 라이브러리의 **JPA PostLoad 방식**을 적용하여, application.yml 설정만으로 Entity 필드 마스킹이 자동 적용되도록 함

## 적용 방식
- **JPA PostLoad EventListener**: DB에서 Entity 로드 시점에 자동 마스킹
- **설정 기반**: application.yml에 필드명과 마스킹 타입만 지정

## 작업 목록

### 1. application.yml에 마스킹 설정 추가
**파일**: `src/main/resources/application.yml`

```yaml
masking:
  enabled: true
  columns:
    userId: USER_ID
    username: NAME
```

### 2. 기존 Masker.java 삭제 및 import 변경
**삭제 파일**: `src/main/java/com/ktown4u/capybara/Masker.java`

**import 변경 대상 파일** (6개):
| 파일 | 변경 내용 |
|------|----------|
| `domain/ContentComment.java:69` | import 변경 |
| `projections/ReviewDto.java:33` | import 변경 |
| `projections/ReviewCommentDto.java:23` | import 변경 |
| `CreateReview.java:185` | import 변경 |
| `PagedEventComments.java:153` | import 변경 |
| `CreateEventComment.java:116` | import 변경 |

```java
// 변경 전
import com.ktown4u.capybara.Masker;

// 변경 후
import com.ktown4u.masking.Masker;
```

### 3. 중복 마스킹 제거 (PostLoad 적용 후)
User Entity에 PostLoad 마스킹이 적용되면, User 연관을 통해 조회되는 userId/username은 이미 마스킹됨.
수동 마스킹 호출 제거 필요:

| 파일 | 현재 코드 | 변경 후 |
|------|----------|---------|
| `PagedEventComments.java:153` | `Masker.maskUserId(dto.user().userId())` | `dto.user().userId()` |
| `CreateEventComment.java:116` | `Masker.maskUserId(comment.user().userId())` | `comment.user().userId()` |

### 4. 테스트 파일 수정
**파일**: `src/test/kotlin/com/ktown4u/capybara/MaskerTest.kt`
- 테스트 대상을 라이브러리 Masker로 변경
- 또는 테스트 삭제 (라이브러리에서 이미 테스트됨)

## 마스킹 로직 차이점 (주의)

| 입력 | 기존 capybara | 라이브러리 |
|------|--------------|-----------|
| `user@example.com` | `use*******` | `u***@example.com` |
| `username01` | `use*******` | `use*******` (동일) |

**변경점**: 이메일 형식의 userId는 도메인(@example.com)이 유지됨

## 작업 순서

### Phase 1: 기본 설정
1. `application.yml`에 masking 설정 추가
2. 기존 `Masker.java` 삭제
3. 6개 파일에서 import를 `com.ktown4u.masking.Masker`로 변경

### Phase 2: DTO Projection 마스킹 대응
JPQL `new` 생성자 쿼리는 PostLoad가 적용되지 않으므로 별도 처리 필요

| Dao | 쿼리 | 마스킹 필드 | 대응 방안 |
|-----|------|------------|----------|
| `ContentItemCommentDao` | `findRootComments`, `findReplyingComments` | `u.userId`, `u.username` | `ContentItemCommentDto.withMaskedUserId()` 추가 |
| `ReviewCommentDao` | `listComments`, `listCommentsForAdmin`, `listReplyingComments` | `rc.user.userId`, `rc.user.username` | 기존 `withMaskedUserId()` import 변경 |
| `ReviewDao` | `pagedBestReviews`, `pagedReviews`, `pagedReviewsByUserNo`, `reviewBy`, `pagedReviewsForAdmin` | `r.userId`, `r.username` | 기존 `withMaskedUserId()` import 변경 |
| `UserDao` | `findByUserNo` | `u.userId`, `u.username` | `UserDto.withMaskedUserId()` 추가 |
| `EventCommentDao` | `listComments` | `c.user` (User Entity 전달) | ✅ User Entity의 PostLoad 적용됨 |

**수정 대상 DTO 파일**:

| 파일 | 현재 상태 | 필요 작업 |
|------|----------|----------|
| `projections/ReviewDto.java` | `withMaskedUserId()` 있음 | import 변경 + `username` 마스킹 추가 |
| `projections/ReviewCommentDto.java` | `withMaskedUserId()` 있음 | import 변경 + `userName` 마스킹 추가 |
| `projections/ContentItemCommentDto.java` | 마스킹 없음 | `withMaskedUserId()` 메서드 추가 |
| `projections/UserDto.java` | 마스킹 없음 | `withMaskedUserId()` 메서드 추가 |

### Phase 3: 서비스 레이어 마스킹 호출 확인
DTO Projection 결과를 반환하는 서비스에서 `withMaskedUserId()` 호출 확인/추가

| 서비스/클래스 | 사용하는 DTO | 확인 필요 |
|--------------|-------------|----------|
| `GetContentComment.java` | `ContentItemCommentDto` | ✅ |
| `PagedReviewComments.java` | `ReviewDto`, `ReviewCommentDto` | ✅ |
| `PagedEventComments.java` | `EventCommentDto` | ✅ (User Entity 사용) |

### Phase 4: 중복 마스킹 제거
User Entity에 PostLoad 마스킹이 적용되면 User 연관 조회 시 중복 마스킹 제거:
- `PagedEventComments.java:153` - `Masker.maskUserId()` 호출 제거
- `CreateEventComment.java:116` - `Masker.maskUserId()` 호출 제거

### Phase 5: 테스트 및 검증
1. 테스트 실행: `./gradlew test`
2. MaskerTest.kt 정리 (라이브러리 테스트로 대체)
3. GraphQL API 응답에서 마스킹 확인

## 검증 방법

```bash
# 테스트 실행
./gradlew test

# 애플리케이션 실행 후 GraphQL 쿼리로 마스킹 확인
```

## Uncertainty Map

### 확신이 낮은 부분
1. ~~**DTO Projection 미적용**~~: ✅ 조사 완료 - Phase 2에서 대응 방안 수립
2. **캐시 영향**: Redis 캐시에 마스킹된 데이터가 저장될 수 있음 - 운영 시 확인 필요
3. **이메일 마스킹 형식 변경**: ✅ 사용자 승인 완료 - 라이브러리 형식 사용

### 확인 완료 항목
- DTO Projection 사용 쿼리: `ContentItemCommentDao`, `ReviewCommentDao`, `ReviewDao`, `UserDao`
- `EventCommentDao`는 User Entity를 직접 전달하므로 PostLoad 적용됨
