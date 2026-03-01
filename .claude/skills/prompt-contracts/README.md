# prompt-contracts

> 프롬프트를 "창작 브리프"가 아닌 "법적 계약서"처럼 작성하여 모호함과 되돌리기를 제거하는 구조화 스킬

## 만든 배경

Medium 아티클 "I Stopped Vibe Coding and Started Prompt Contracts"에서 영감을 받아 2026-02-18 msbaek_vault 프로젝트에서 생성되었습니다. 모호한 프롬프트로 인해 작업 시간의 30%를 되돌리기에 소비하는 "바이브 코딩"을 방지하기 위해, Goal/Constraints/Output Format/Failure Conditions 4요소 구조를 brainstorming/writing-plans 스킬에 통합하여 명확한 명세 작성을 강제합니다.

## 사용법

### 호출 방법

brainstorming, planning, 설계, 기능 개발 관련 작업 시 자동으로 적용되며, 명시적으로 호출할 필요는 없습니다. 다음과 같은 상황에서 4요소 구조를 프롬프트에 포함하면 됩니다.

- Brainstorming 시: 각 설계 접근법에 Goal/Constraints/Failure Conditions 명시
- Planning 시: 전체 plan에 Goal/Constraints, 각 작업(task)에 Output Format/Failure Conditions 포함
- 기능 구현 요청 시: Goal/Constraints/Format/Failure Conditions를 프롬프트에 명시

### 예시

#### 기능 구현 요청 (완전한 계약)

```
> Build the /dashboard page.
>
> GOAL: Display user's active projects with real-time updates.
> First meaningful paint under 1 second. User can create, archive,
> and rename projects inline.
>
> CONSTRAINTS: Convex useQuery for data, no polling, no SWR.
> Clerk useUser() for auth check. Redirect to /sign-in if
> unauthenticated. Max 150 lines per component file.
>
> FORMAT: Page component in app/dashboard/page.tsx (server component
> wrapper), client component in components/dashboard/ProjectList.tsx,
> Convex query in convex/projects.ts. Tailwind only.
>
> FAILURE CONDITIONS:
> - Uses useState for data that should be in Convex
> - Any component exceeds 150 lines
> - Fetches data client-side when it could be server-side
> - Uses any UI library besides Tailwind utility classes
> - Missing loading and error states
> - Missing TypeScript types on any function parameter
```

#### 최소 시작 (3가지만)

```
> 사용자 온보딩 함수 만들어줘
>
> GOAL: 사용자가 회원가입 후 프로필을 완성하면 대시보드로 리디렉트 (5초 이내 검증 가능)
> CONSTRAINT: Convex mutation 사용, Clerk auth 통합
> FAILURE CONDITION: 파일이 150줄 초과하면 수용 불가
```

## 주요 기능

### 1. Goal — 테스트 가능한 성공 기준

"완료"를 1분 이내에 검증 가능하도록 정의합니다. 상세함보다 **테스트 가능성(testability)** 이 핵심입니다.

**Before (바이브):** "앱에 구독 시스템 추가해줘"
**After (계약):** "사용자가 3개 티어(free/pro/team)에 구독하고, 즉시 업/다운그레이드하며, /settings/billing에서 결제 상태를 볼 수 있는 Stripe 구독 관리를 구현하라. 성공 = 무료 사용자가 Pro에 구독하고, Stripe 대시보드에서 과금을 확인하고, 5초 내에 게이트된 기능에 접근할 수 있는 것."

### 2. Constraints — 비협상 경계

기술 스택, 패턴, 금지 항목을 명시하여 Claude Code가 임의로 스택을 재발명하는 것을 방지합니다.

**Before (바이브):** "모범 사례 적용해줘"
**After (계약):**
```
CONSTRAINTS:
- Convex useQuery for data, no polling, no SWR
- Clerk useUser() for auth check
- Tailwind only — no CSS modules, no styled-components
- Max 150 lines per component file
```

### 3. Output Format — 구체적 구조 지시

파일 위치, 함수 시그니처, 반환 타입을 명시하여 유지보수성을 최적화합니다.

**Before (바이브):** "사용자 온보딩 함수 만들어줘"
**After (계약):**
```
FORMAT:
1. Convex function in convex/users.ts (mutation, not action)
2. Zod schema for input validation in convex/schemas/onboarding.ts
3. TypeScript types exported from convex/types/user.ts
4. Include JSDoc on the public function
5. Return { success: boolean, userId: string, error?: string }
```

### 4. Failure Conditions — 가드레일

"좋은 것"을 정의하는 대신 "나쁜 것"을 명시합니다. Goal이 당근이라면 Failure Conditions는 채찍입니다.

```
FAILURE CONDITIONS:
- Uses useState for data that should be in Convex
- Any component exceeds 150 lines
- Fetches data client-side when it could be server-side
- Uses any UI library besides Tailwind utility classes
- Missing loading and error states
- Missing TypeScript types on any function parameter
```

### CLAUDE.md 영구 제약 계층

프로젝트별 Constraints를 `CLAUDE.md`에 문서화하여 세션 간 일관성을 보장합니다.

```markdown
# CLAUDE.md — Project Constraints (always active)

## Stack (non-negotiable)
- Frontend: Next.js 14+ App Router, TypeScript strict
- Backend: Convex for real-time data, Supabase for auth + storage
- Styling: Tailwind only — no CSS modules, no styled-components

## Hard Rules
- Never install a new dependency without asking first
- Never modify the database schema without showing the migration plan
- Environment variables go in .env.local, never hardcoded
```

새 세션 시작 시 "Read CLAUDE.md and confirm you understand the project constraints before doing anything." 핸드셰이크 절차로 제약을 확인합니다.

## 의존성

- 독립 실행 가능 (외부 의존성 없음)
- brainstorming, writing-plans 스킬과 함께 사용 시 자동 통합

## 참고

- 영감 출처: Medium 아티클 "I Stopped Vibe Coding and Started Prompt Contracts"
- 핵심 철학: "60초 더 생각해서 60분 추측 제거"
- 최소 시작: Goal 1개 + Constraint 1개 + Failure Condition 1개만으로도 즉각적인 효과
