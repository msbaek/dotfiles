# Write-In-My-Voice 설계 문서

**날짜:** 2026-04-25
**상태:** 승인됨

## Goal (테스트 가능한 완료 조건)

1. `~/.claude/skills/humanize-korean/` 에 im-not-ai가 설치되어 `/humanize-korean` 으로 호출 가능
2. 윤문 시 일반 자연 한국어가 아닌 백명석 고유 문체로 변환
3. `/write-in-my-voice <주제>` 로 브런치 스타일 초안 생성 가능

## Constraints (비협상 제약)

- im-not-ai 원본 탐지 파이프라인(ai-tell-taxonomy.md) 수정 없음
- 의미 불변 원칙(content-fidelity-auditor) 반드시 유지
- voice profile은 단일 파일(`voice-profile-msbaek.md`)로 두 스킬이 공유
- 탐지기·윤문가는 sonnet, 감사관·리뷰어는 opus (Opus quota 관리)

## 아키텍처

```
브런치 15-20개 글 크롤링
        ↓
voice-profile-msbaek.md (공유)
        │
        ├─→ humanize-korean 스킬 (im-not-ai 기반, 윤문 타겟을 내 목소리로)
        │
        └─→ write-in-my-voice 스킬 (초안 생성)
```

## 배포 구조

```
~/.claude/skills/
├── humanize-korean/
│   ├── SKILL.md                         # 경로 수정 + voice profile 주입
│   ├── agents/
│   │   ├── ai-tell-detector.md          # opus → sonnet
│   │   ├── korean-style-rewriter.md     # opus → sonnet + voice profile 참조
│   │   ├── content-fidelity-auditor.md  # opus 유지
│   │   └── naturalness-reviewer.md      # opus 유지
│   └── references/
│       ├── ai-tell-taxonomy.md          # 원본 유지
│       ├── rewriting-playbook.md        # 원본 유지
│       └── voice-profile-msbaek.md      # 신규 — 공유 프로필
└── write-in-my-voice/
    └── SKILL.md                         # 신규 스킬
```

## 컴포넌트 설계

### 1. voice-profile-msbaek.md

브런치 최신 글 기준 15-20개 샘플링으로 추출한 문체 프로필.
샘플링 전략: 최신 5개 + 조회수 높은 글 위주로 10-15개 추가 (총 15-20개).

**섹션 구성:**
- 주요 주제 영역
- 문장 리듬 패턴
- 서사 구조 (개인경험 → 원리 → 실무)
- 어조 특징 (나/우리 교차, 겸손+확신)
- DO/AVOID 표현 패턴
- 단락 구성 규칙
- 실제 예시 문장 (패턴당 2-3개, 브런치에서 직접 추출)

### 2. humanize-korean (im-not-ai 수정)

| 수정 항목 | 변경 전 | 변경 후 |
|----------|---------|---------|
| 설치 경로 | `/Users/epoko77_m5/humanize-ko/` | `~/.claude/skills/humanize-korean/` |
| `ai-tell-detector` model | opus | sonnet |
| `korean-style-rewriter` model | opus | sonnet |
| `korean-style-rewriter` 지침 | 자연스러운 한국어 | voice-profile-msbaek.md 참조 |
| `content-fidelity-auditor` model | opus | opus (유지) |
| `naturalness-reviewer` model | opus | opus (유지) |
| `_workspace/` 경로 | 하드코딩 절대경로 | `~/.claude/skills/humanize-korean/_workspace/` |

### 3. write-in-my-voice 스킬

**voice profile 참조 경로:**
`~/.claude/skills/humanize-korean/references/voice-profile-msbaek.md`
(절대 경로로 SKILL.md에 명시)

**파이프라인 (2단계):**

```
1단계 — 구조 설계:
  입력: 주제/키워드
  voice-profile-msbaek.md 로드
  → 제목 3개 후보 제안
  → 섹션 구조 초안
  → 사용자 피드백 대기

2단계 — 본문 작성:
  사용자 승인 구조
  → 섹션별 본문 생성 (voice profile 패턴 적용)
  → 실제 예시 문장 참조
  → 브런치 마크다운 형식 출력
```

**트리거:**
```
/write-in-my-voice TDD를 처음 배울 때의 어려움
/write-in-my-voice 코드 리뷰 문화 만들기
```

**권장 2단계 워크플로우:**
```
/write-in-my-voice <주제>  →  초안 생성
                               ↓
                    /humanize-korean  →  AI 티 제거 + 목소리 강화
```

## 구현 순서

1. 브런치 15-20개 글 크롤링 (Playwright MCP)
2. `voice-profile-msbaek.md` 생성
3. im-not-ai GitHub에서 소스 클론
4. SKILL.md 경로 수정 + `_workspace` 경로 수정
5. 에이전트 model 교체 (탐지기·윤문가 → sonnet)
6. `korean-style-rewriter.md` 에 voice profile 참조 추가
7. `write-in-my-voice/SKILL.md` 신규 작성
8. 동작 검증 (샘플 텍스트로 테스트)

## Failure Conditions

- voice profile이 너무 추상적이면 LLM이 스타일을 모방하지 못함 → 실제 예시 문장 섹션 필수
- 경로 하드코딩 누락 시 스킬 로드 실패
- content-fidelity-auditor를 sonnet으로 교체하면 의미 검증 품질 저하 위험 → opus 유지
