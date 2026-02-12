---
description: "AI 코드 폐기 결정 지원. 구현이 꼬였을 때 revert 후 재시도 가이드."
---

# Happy to Delete - 과감한 폐기와 재시작

출처: [Augmented Coding Patterns](https://lexler.github.io/augmented-coding-patterns/patterns/happy-to-delete/)

## 문제

개발자는 작성한 코드에 감정적으로 집착하여 실패한 시도를 삭제하기 꺼린다. AI 코드는 "재생성 비용이 거의 0"인데도 수작업 코드처럼 취급하여, 근본적으로 잘못된 구현 위에 패치를 쌓는다.

## 핵심 원칙

> "삭제할 용기가 있으면 '이걸 꼭 살려야 한다'는 압박이 사라지고, 역설적으로 더 빠르게 더 나은 결과에 도달한다."

## 프로세스

### 1단계: 현재 상황 진단

다음 중 하나라도 해당되면 **지금 revert**:
- [ ] 2-3회 반복 수정해도 개선되지 않음
- [ ] 패치가 새로운 문제를 만들어냄
- [ ] "이건 왜 이렇게 되어있지?" 의문이 반복됨
- [ ] AI가 자기 모순적 설명을 하기 시작함

### 2단계: Revert 실행

```bash
# 체크포인트로 복귀
git stash  # 또는 git checkout -- .
```

### 3단계: 교훈 반영 후 재시도

- 실패 원인을 1-2문장으로 정리
- 프롬프트를 명확한 제약 조건과 함께 재작성
- 새로운 시도 시작 (이전 코드 참조하지 않음)

## 판단 기준

| 상황 | 행동 |
|------|------|
| 1회차 수정으로 해결 | 계속 진행 |
| 2-3회차에 개선 보임 | 조금 더 시도 |
| 2-3회차에 개선 없음 | **즉시 revert** |
| 패치가 새 버그 생성 | **즉시 revert** |

## 관련 패턴

- **유사**: Parallel Implementations, `/augmented:parallel-impl`
- **해결**: Sunk Cost 안티패턴
- **연관**: `superpowers:using-git-worktrees` (격리된 작업 공간에서 부담 없이 폐기 가능)
