---
argument-hint: "[kr|en] [transcript or YouTube URL]"
description: "Youtube URL 또는 트랜스크립트 → 백그라운드로 번역/정리 → obsidian 문서 생성 (첫 번째 인자로 언어 지정: kr|en, 기본값: en)"
color: yellow
---

# YouTube Summarize - $ARGUMENTS

YouTube URL 또는 트랜스크립트를 받아 번역/정리하여 Obsidian 문서를 생성합니다.

## 실행 모드 결정

먼저 환경변수를 확인한다:

```bash
echo "${OBSIDIAN_EXEC:-}"
```

- 출력이 `1`이면: **inline 모드** — 아래 규칙에 따라 직접 실행
- 출력이 비어 있으면 **그리고** $ARGUMENTS에 YouTube URL(`https://`로 시작)이 포함되어 있으면: **tmux 위임 모드**

  $ARGUMENTS에서 언어 옵션(`kr`/`en`)과 URL을 파싱하여:
  ```bash
  ~/bin/obsidian-summarize.sh --with-url youtube-{lang} {URL}
  ```
  (언어 미지정 시 `youtube-en` 사용)

  안내: "`obsidian` tmux 세션에서 진행 확인: `tmux attach -t obsidian`"
  tmux 위임 후 이 스킬의 나머지 내용은 실행하지 않는다.

- 출력이 비어 있고 트랜스크립트가 직접 전달된 경우: **inline 모드** — 아래 규칙에 따라 직접 실행

## 공통 규칙

`~/.claude/commands/obsidian/shared-rules.md`의 모든 규칙을 따른다.
(번역 규칙, frontmatter, target audience, related notes, wikilink, atomic note, progress, 백그라운드 실행 모델)

## YouTube 요약 구조

### 1. 핵심 요약
전체 내용을 2-3 문단으로 요약.

### 2. 상세 내용
영상 흐름에 따라 시간 기반으로 섹션을 나누고, 각 섹션에 타임스탬프 범위를 표기.

형식:
### [00:00 - 05:30] 섹션 제목
내용 정리...

### [05:30 - 12:15] 섹션 제목
내용 정리...

타임스탬프는 transcript의 start 시간 데이터를 활용한다.
각 섹션의 시작 시간은 해당 섹션 첫 발화의 start, 종료 시간은 다음 섹션 첫 발화의 start로 결정.

### 3. 시사점
원문에 명시된 권장사항, 교훈, 실무 적용 사례를 5-7개 bullet point로 정리.
각 시사점에는 원문에서 인용 가능한 근거를 함께 제시.

## 언어 옵션 처리

첫 번째 인자로 언어 옵션 확인 (기본값: en):
- `kr` 또는 `ko`: 한글 트랜스크립트 우선 다운로드
- `en`: 영어 트랜스크립트 우선 다운로드 (기본값)
- 첫 단어가 언어 옵션이 아니면 전체를 내용으로 처리

## 콘텐츠 추출

### YouTube URL인 경우

`~/bin/download-youtube-transcript` 스크립트를 사용하여 JSON 형식으로 메타데이터와 트랜스크립트 추출.

```bash
# 언어 옵션에 따라 실행 (첫 번째 언어 실패 시 대체 언어로 재시도)
if [ "$LANG_OPTION" = "kr" ]; then
    YOUTUBE_DATA=$(~/bin/download-youtube-transcript -f json -l kr "$URL" 2>/dev/null || ~/bin/download-youtube-transcript -f json -l en "$URL")
else
    YOUTUBE_DATA=$(~/bin/download-youtube-transcript -f json -l en "$URL" 2>/dev/null || ~/bin/download-youtube-transcript -f json -l kr "$URL")
fi
```

- 고유 임시 파일: `/tmp/youtube_data_${VIDEO_ID}_${TIMESTAMP}.json` (동시 실행 충돌 방지)
- 동시 실행 가능 (stateless HTTP, 직렬화 불필요)

### 트랜스크립트인 경우

입력 데이터를 직접 처리.

### 메타데이터 자동 생성 (URL인 경우)

- id: 동영상 제목 (자동 추출)
- aliases: 동영상 제목의 한국어 번역
- author: 채널명 (소문자, 공백은 '-'로 변경)
- source: 원본 YouTube URL

## 처리 프로세스 요약

1. (백그라운드 모드 시) Progress 파일 생성 → subagent 시작 → 즉시 반환
2. 언어 옵션 파싱
3. YouTube 데이터 추출 (download-youtube-transcript)
4. Wikilink 후보 파악 (vis search)
5. 번역/요약 (shared-rules + youtube 구조, 타임스탬프 포함, wikilink 포함)
6. 문서 저장 ($VAULT_ROOT/001-INBOX/)
7. Related Notes 추가 (vis search)
8. Atomic Note 후보 추가
9. (백그라운드 모드 시) Progress 파일 업데이트
10. 임시 파일 정리 (`rm -f "$YOUTUBE_TEMP_FILE"`)
