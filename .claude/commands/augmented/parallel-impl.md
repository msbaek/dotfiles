---
description: "체크포인트 후 git worktree로 복수 구현 동시 진행. 불확실한 접근법 시 호출."
---

# Parallel Implementations - 병렬 구현

출처: [Augmented Coding Patterns](https://lexler.github.io/augmented-coding-patterns/patterns/parallel-implementations/)

## 문제

AI는 비결정적(non-deterministic)이다. 주사위를 굴리는 것과 같아서 첫 시도에 원하는 결과를 얻기 어렵다. 실패를 순차적으로 디버깅하는 것보다 여러 시도를 동시에 실행하는 것이 효율적이다.

## 핵심 원칙

> 토큰 비용(저렴)을 개발자 시간(비쌈)으로 교환한다.

## 프로세스

### 1단계: 체크포인트 생성

```bash
# 계획을 파일로 저장하고 커밋
git add . && git commit -m "checkpoint: before parallel implementation"
```

### 2단계: 작업 공간 분기

```bash
# git worktree로 병렬 작업 공간 생성
git worktree add ../project-attempt-1 -b attempt-1
git worktree add ../project-attempt-2 -b attempt-2
git worktree add ../project-attempt-3 -b attempt-3
```

### 3단계: 병렬 구현

- 각 worktree에서 서로 다른 AI 세션으로 동시 구현
- 같은 요구사항, 다른 프롬프트/접근법

### 4단계: 결과 비교 및 선택

- 모든 결과를 리뷰
- 최선의 구현 선택 또는 여러 시도의 장점 결합
- 선택되지 않은 worktree 정리

## 두 가지 모드

### 실패 완화 (Failure Mitigation)
복잡한 기능에 대해 3-5개 병렬 시도. 일부는 실패, 일부는 성공 → 순차 디버깅 없이 전진.

### 해결 공간 탐색 (Solution Space Exploration)
속도보다 품질이 중요할 때 여러 작동하는 버전을 비교 → 특히 UI, 게임 메카닉 등 창의적 작업에 효과적.

## 관련 패턴

- **유사**: `/augmented:happy-to-delete` (폐기에 대한 심리적 저항 제거)
- **연관**: `superpowers:using-git-worktrees`, `superpowers:dispatching-parallel-agents`
