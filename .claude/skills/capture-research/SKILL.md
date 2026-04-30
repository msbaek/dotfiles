---
name: capture-research
description: 현재 세션의 조사/분석/연구/평가 결과를 Obsidian vault ($VAULT_ROOT/001-INBOX/)에 한국어 마크다운 문서로 저장. frontmatter 자동 생성, vis hybrid search로 Related Notes 자동 추가. 외부 URL/YouTube 요약은 범위 밖.
allowed-tools:
  - Bash(echo:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(head:*)
  - Bash(tail:*)
  - Bash(lsof:*)
  - Bash(curl:*)
  - Bash(vis:*)
  - Bash(python3:*)
  - Bash(date:*)
  - Read
  - Write
  - Edit
when_to_use: |
  Use when the user wants to save the current session's analysis, research, evaluation, comparison, or strategic recommendation as a detailed Korean Obsidian note in the vault's 001-INBOX folder. The input is the CURRENT SESSION CONTEXT (previous assistant turns or user-specified topic), NOT an external URL or YouTube video.

  Trigger phrases (Korean): "이 내용을 obsidian에 저장해줘", "vault에 저장", "분석 결과를 obsidian 문서로", "조사 결과 정리", "이번 세션 결과 저장", "세션 산출물 문서화", "이 내용을 자세히 작성해줘 (vault에)"

  Trigger phrases (English): "save this analysis to vault", "research to vault", "capture session to obsidian"

  Do NOT invoke for:
  - External URL summaries (use obsidian:summarize-article)
  - YouTube video summaries (use obsidian:summarize-youtube)
  - Adding Related Notes to existing files (use obsidian:related-contents)
  - Adding tags to existing files (use obsidian:add-tag)
argument-hint: "[--brief|--standard|--detailed] [저장할 주제 힌트]"
arguments:
  - length_mode
  - content_hint
---

# Capture Session Research to Obsidian Vault

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 A 적용**
(model="sonnet", run_in_background=false, args=skill 호출 인자, 옵션=--brief|--standard|--detailed)

main context에서 직접 실행 금지.

현재 세션의 조사/분석/연구/평가/비교/권고 결과를 Obsidian vault의 `001-INBOX/` 폴더에 자세한 한국어 마크다운 문서로 저장합니다.

## Inputs

- `$length_mode`: 길이 모드 — `--brief` (1-2KB), `--standard` (5-10KB), `--detailed` (15-30KB, **기본값**)
- `$content_hint`: 저장할 주제 힌트 (선택). 없으면 세션 최근 assistant turn을 후보로 제시 후 사용자 확인

## Goal

- 한국어 제목의 `.md` 파일이 `$VAULT_ROOT/001-INBOX/`에 저장됨
- frontmatter가 기존 vault 패턴과 일관 (title/aliases/tags hierarchical/created/author/source)
- 본문에 표·코드블록·wikilink 자연스럽게 포함 (기존 vault 2-3개 이상 연결)
- `## Related Notes` 섹션에 vis hybrid search + rerank top 5 wikilink (1줄 컨텍스트)
- **저장 전** 사용자가 frontmatter와 파일명 검토하고 승인

## 범위 (중요)

**다루는 것**: 세션 최근 turn의 분석·연구·평가·비교·결정·전략 권고. Claude가 정리한 도구 비교표, 아키텍처 권고, 로드맵, trade-off.

**다루지 않는 것**:

| 상황 | 사용할 skill |
|------|-------------|
| 외부 URL 요약 | `obsidian:summarize-article` |
| YouTube 영상 요약 | `obsidian:summarize-youtube` |
| 기존 vault 파일에 Related Notes 추가 | `obsidian:related-contents` |
| 기존 vault 파일 태그 추가 | `obsidian:add-tag` |

## Steps

### 1. 입력 파악

- `$content_hint` 있으면 → 저장 주제 확정
- 없으면 세션 최근 2-3 turn 요약을 사용자에게 제시:
  > "다음 내용을 저장할까요?\n[요약 2-3 문장]\n\n다른 주제면 알려주세요."
- `$length_mode` 기본 `--detailed`

**Success criteria**: 저장 주제 + 길이 모드 확정.

**Human checkpoint**: 주제 모호 시 확인 후 진행.

### 2. Vault 컨텍스트 학습

```bash
echo "${VAULT_ROOT:?VAULT_ROOT 환경변수 미설정}"
INBOX="$VAULT_ROOT/001-INBOX"

find "$INBOX" -maxdepth 2 -name "*.md" -type f -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null | head -5 \
  | while read f; do echo "--- $(basename "$f") ---"; head -20 "$f"; echo ""; done
```

수집: `tags` 계층, `aliases` 패턴, `source` 형식, 커스텀 필드.

**Success criteria**: 최소 3개 기존 파일 frontmatter 샘플 확보.

### 3. Frontmatter 초안 생성

```yaml
---
title: "한국어 제목 — 핵심 구분"
aliases:
  - 동일 개념 다른 표현
  - 영문 검색 alias
created: YYYY-MM-DD
author: msbaek
source: "session 분석 (YYYY-MM-DD, 프로젝트명)"
tags:
  - ai/tools/claude-code
  - ai/claude/memory
  - knowledge-management/second-brain
related: []
---
```

**Rules**:
- `tags` hierarchical (`/`), 기존 vault tag **2개 이상 재사용**
- `aliases` 2-3개 (한국어 + 영문)
- `created` = `date +%Y-%m-%d`
- `author` 항상 `msbaek`
- `source`는 세션 컨텍스트 (URL 아님)
- `related: []` 빈 배열 (Related Notes는 본문 섹션)

**Success criteria**: YAML valid, 필수 필드, 기존 tag 2개 이상 재사용.

### 4. 파일명 생성

- 한국어 dash-separated, 최대 80자
- 핵심 키워드 3-5개 연결
- 충돌 시 `-2`, `-3` suffix

```bash
FILENAME="한국어-키워드1-키워드2-키워드3.md"
FULLPATH="$INBOX/$FILENAME"
if [ -e "$FULLPATH" ]; then
  BASE="$(basename "$FILENAME" .md)"
  N=2
  while [ -e "$INBOX/${BASE}-${N}.md" ]; do N=$((N+1)); done
  FILENAME="${BASE}-${N}.md"
  FULLPATH="$INBOX/$FILENAME"
fi
```

**Success criteria**: 80자 이내, 충돌 없음.

### 5. 본문 작성

| 모드 | 크기 | 구조 |
|------|------|------|
| `--brief` | 1-2KB | TL;DR + 핵심 결론 2-3개 + 1 표 |
| `--standard` | 5-10KB | TL;DR + 3-5 섹션 + 표 1-2개 + 코드 1-2개 |
| `--detailed` | 15-30KB | TL;DR + 배경 + 진단 + 다차원 비교 + 갭/솔루션 + 로드맵 + anti-pattern + 트러블슈팅 + 결론 + 참고자료 |

**Rules**:
- 본문 한국어, 기술 용어 영어 그대로
- 표: pipe-markdown, 코드블록: 언어 명시
- wikilink `[[Note-Name]]`로 기존 vault 문서 **최소 2-3개 연결**
- 섹션 번호 매김
- U-shaped attention: TL;DR 맨 앞, 결론 맨 끝

**Human checkpoint**: `--detailed`라도 주제 간단 시 15KB면 충분 — 억지 늘림 금지.

**Success criteria**: 모드별 적정 길이, 필수 요소 포함.

### 6. vis daemon 자동 처리 + Related Notes 검색

```bash
# 6a. daemon 확인
if ! lsof -nP -iTCP:8741 -sTCP:LISTEN >/dev/null 2>&1; then
  vis serve
fi

# 6b. 인덱스 준비 대기 (최대 60초)
for i in {1..12}; do
  STATUS=$(curl -s "http://localhost:8741/health" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"indexed={d.get('indexed')}\")" 2>/dev/null || echo "loading")
  echo "[${i}/12] $STATUS"
  [[ "$STATUS" == *"indexed=True"* ]] && break
  sleep 5
done

# 6c. hybrid search + rerank (2-4 query, 다양성)
parse_results() {
  python3 -c "
import sys, json, os
d = json.load(sys.stdin)
VR = os.environ.get('VAULT_ROOT','')
for r in d.get('results', [])[:8]:
    p = r['path'].replace(VR, '').lstrip('/')
    print(f\"{r['score']:.3f}|{p}|{r.get('snippet','')[:120]}\")
"
}

for Q in "핵심 키워드 1" "핵심 키워드 2" "다른 각도 키워드"; do
  echo "=== Q: $Q ==="
  curl -s --get --data-urlencode "query=$Q" \
    "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=8" \
    | parse_results
done
```

**Rules 선별 기준**:
- self(생성 중 파일) 제외
- daily notes(`notes/dailies/`, `dailies/`) 제외
- 점수 < 1.0 skip
- 카테고리 다양성 (한 주제만 5개 X)

**Success criteria**: 5개 후보, 각 점수 > 1.0 또는 명확히 관련.

### 7. Related Notes 섹션 추가

```markdown
## Related Notes

- [[Note-Name-1]] — 1줄 컨텍스트 (왜 관련, 어떤 측면)
- [[Note-Name-2]] — ...
- [[Note-Name-3]] — ...
- [[Note-Name-4]] — ...
- [[Note-Name-5]] — ...
```

**Rules**:
- 정확히 5개
- 각 1줄 컨텍스트 필수
- wikilink는 `.md` 제외
- 실존 파일 검증

**Success criteria**: 5 wikilink, 모두 실존, 각 의미 있는 컨텍스트.

### 8. 사용자 검토 prompt → 저장

사용자에게 제시:

```
### 검토 요청
- 파일: $VAULT_ROOT/001-INBOX/<filename>.md
- frontmatter: title/aliases/tags/source
- 본문: ~XKB, N개 섹션
- Related Notes: [[a]], [[b]], [[c]], [[d]], [[e]]
```

**Human checkpoint (필수)**:
- OK → `Write` tool 저장 + 경로 보고
- 수정 요청 → 해당 부분 수정 후 재확인 (최대 3회)
- 취소 → 저장 없이 종료

**Success criteria**: 사용자 승인, `Write` 성공, 경로 + 크기 보고.

## Anti-Patterns (절대 금지)

| Anti-pattern | 이유 |
|-------------|------|
| 외부 URL을 입력으로 받아 저장 | 범위 밖 — `obsidian:summarize-article` |
| YouTube 영상 요약 | 범위 밖 — `obsidian:summarize-youtube` |
| frontmatter 100% 자동 저장 | Step 8 human checkpoint 필수 |
| `001-INBOX` 외 폴더에 저장 | 정책상 hardcoded, `--dir` 미지원 |
| daily notes를 Related Notes에 포함 | `<when-creating-obsidian-document>` 룰 위반 |
| Related Notes ≠ 5개 | 정책상 정확히 5개 |
| Related Notes 1줄 컨텍스트 생략 | 품질 저하 |
| 본문 영어 작성 | 한국어 기본 (기술 용어만 영어) |
| 80자 초과 파일명 | 가독성/호환성 |
| vis daemon 실패 시 Related Notes 생략 저장 | Step 7 실패 = skill 전체 실패로 보고 |

## 좋은 예시 (참조)

`$VAULT_ROOT/001-INBOX/Claude-Code-세션-메모리-효율화-전략-claude-mem-대안.md`
- 26KB, 605줄, 11 섹션
- 11 hierarchical tags, 3 aliases
- 11 표 + 5 코드블록
- 5 Related Notes (각 1줄 컨텍스트)
- 8 wikilink (본문 + Related Notes)

이 파일 구조가 `--detailed` 모드의 기준입니다.
