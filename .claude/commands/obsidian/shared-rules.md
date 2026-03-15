# Obsidian Summarize 공통 규칙

이 파일은 `/obsidian:summarize-article`과 `/obsidian:summarize-youtube`에서 공통으로 참조하는 규칙이다.
개별 스킬에서 `~/.claude/commands/obsidian/shared-rules.md`의 모든 규칙을 따른다고 명시한다.

## Target Audience

- 컴퓨터공학 학사/석사, 25년 이상 소프트웨어 개발 경험
- 영어 원문을 빠르게 읽기 어려움
- 관심 분야: OOP, TDD, Design Patterns, Refactoring, DDD, Clean Code,
  Architecture (MSA, Modulith, Hexagonal, vertical slicing),
  Code Review, Agile, Spring Boot, 개발 조직 구축, 개발자 성장/코칭
- 학습하고 정리한 내용을 업무와 강의에 활용

## 번역 규칙

You are a professional translator and software development expert.

1. 한국어로 번역. 기술 용어는 첫 등장 시 영문 병기 — 가능한 많이 포함
2. 직역 우선, 자연스러운 한국어 표현
3. 불확실한 부분은 명시적으로 표기
4. 원문에 코드 예제가 있는 경우 모두 포함 (누락 금지)

## 출력 형식 규칙

- 원문 내용을 누락 없이 상세하게 정리 (요약이 아닌 정리)
- 각 섹션의 분량은 내용 복잡도에 비례하여 조절
- 복잡한 개념은 비유나 예시로 설명

## yaml frontmatter 형식

```yaml
id: 원문 제목 (영문)
aliases:
  - 원문 제목의 한국어 번역
tags:
  - hierarchical/tag/structure
author: author-name-lowercase-hyphenated
created_at: YYYY-MM-DD HH:MM
related: []
source: 원본 URL
```

- id: 원문에서 추출한 제목
- aliases: 원문 제목의 한국어 번역
- author: 소문자, 공백은 '-'로 변경
- created_at: obsidian 파일 생성 시점
- source: 원본 URL
- tags: `~/.claude/commands/obsidian/add-tag.md` 규칙 준수

## 저장 경로

- 문서: `$VAULT_ROOT/001-INBOX/`
- 첨부파일: `$VAULT_ROOT/ATTACHMENTS/`

## 본문 내 Wikilink (Zettelkasten)

문서 생성 시, vault에 실제 존재하는 노트를 미리 파악하여 본문에 `[[wikilink]]`로 포함한다.

### 프로세스

1. 콘텐츠 추출 후, 번역/요약 전에 핵심 개념 키워드 5-10개를 먼저 추출
2. 각 키워드로 vis daemon HTTP API를 호출 (CLI import 8초 회피):
   ```bash
   curl -s --get --data-urlencode "query=키워드" "http://localhost:8741/search?search_method=hybrid&top_k=3" | jq -r '.results[] | "\(.score) \(.path)"'
   ```
   서버 미실행 시 fallback: `vis search "키워드" --search-method hybrid --top-k 3`
3. 검색 결과 중 유사도가 높고 **실제 존재하는 노트**만 선별 → wikilink 후보 목록 확정
4. 번역/요약 시 wikilink 후보 목록을 프롬프트에 포함하여, 해당 개념이 처음 등장하는 위치에 `[[노트명]]`을 삽입하도록 지시
5. 존재하지 않는 노트는 링크하지 않음 (빈 링크 방지)

### 제약
- 한 문서당 wikilink는 최대 10개
- daily notes, 자기 자신은 제외

## Atomic Note 후보

문서 끝에 별도 섹션으로 추가. 파일은 생성하지 않음.

```markdown
## Atomic Note 후보
- [[제안 노트 제목]] — 핵심 아이디어 한 줄 설명
```

### 규칙
- 3-5개 제안
- 원문에서 독립적으로 의미 있는 아이디어 단위
- 본문에서 이미 wikilink로 연결된 노트는 제외
- vault에 이미 유사한 노트가 있으면 해당 노트와의 관계도 언급

## Related Notes

문서 생성 완료 후, `vis search`를 사용하여 관련 문서를 찾고 Related Notes 섹션을 **자동으로** 추가한다.
사용자가 inbox 검토 시 수정하므로 별도 승인 단계 없이 바로 적용한다.

1. 생성된 문서의 제목과 핵심 키워드 2-3개로 vis daemon HTTP API 호출:
   ```bash
   curl -s --get --data-urlencode "query=키워드" "http://localhost:8741/search?search_method=hybrid&rerank=true&top_k=10" | jq -r '.results[] | "\(.score) \(.path)"'
   ```
   서버 미실행 시 fallback: `vis search "키워드" --search-method hybrid --rerank --top-k 10`
2. 자기 자신, daily notes(`notes/dailies/`) 제외, 유사도가 낮은 문서 제외
3. 상위 5개 문서를 문서 하단에 자동 추가 (승인 불필요):
   ```markdown
   ## Related Notes
   - [[문서명]] — 맥락 설명
   ```

## 백그라운드 실행 모델

### 실행 모드 판단
- `OBSIDIAN_EXEC=1` 환경변수가 설정됨 (obsidian-summarize.sh 경유) → **동기 모드**
- subagent 내부에서 호출 (batch-summarize-urls 등) → **동기 모드**
- Claude 세션에서 직접 호출 → **백그라운드 모드** (subagent로 위임, 컨텍스트 캐시 활용)

### 백그라운드 모드 프로세스

1. Progress 파일 생성 (`.claude/summarize-progress/`)
2. Task tool로 백그라운드 subagent 시작 (`run_in_background: true`)
3. 사용자에게 알림 후 즉시 반환

### Progress 파일

경로: `.claude/summarize-progress/`
파일명: `YYYYMMDD-HHMMSSfff-{type}-{slug}.json` (fff = 밀리초)
- article: `YYYYMMDD-HHMMSSfff-article-{url-slug}.json`
- youtube: `YYYYMMDD-HHMMSSfff-youtube-{video-id}.json`

```json
{
  "url": "...",
  "type": "article|youtube",
  "status": "processing|completed|failed",
  "started_at": "ISO-8601",
  "completed_at": "ISO-8601|null",
  "output_file": "001-INBOX/문서제목.md|null",
  "related_notes_added": [],
  "atomic_notes_suggested": [],
  "error": "에러 메시지|null"
}
```

### 진행 상황 모니터링

`.claude/summarize-progress/` 폴더의 JSON 파일들을 읽어서 상태를 보고:
- `processing`: "처리 중: URL"
- `completed`: "완료: URL → 파일경로"
- `failed`: "실패: URL (에러메시지)"
