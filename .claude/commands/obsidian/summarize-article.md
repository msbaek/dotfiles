---
argument-hint: "[url]"
description: "기술 문서 URL → 백그라운드로 번역/정리 → obsidian 문서 생성"
color: yellow
---

# Article Summarize - $ARGUMENTS

기술 문서 URL을 받아 번역/정리하여 Obsidian 문서를 생성합니다.

## 공통 규칙

`~/.claude/commands/obsidian/shared-rules.md`의 모든 규칙을 따른다.
(번역 규칙, frontmatter, target audience, related notes, wikilink, atomic note, progress, 백그라운드 실행 모델)

## Article 요약 구조

### 1. 핵심 요약
전체 내용을 2-3 문단으로 요약.

### 2. 상세 내용
원문의 heading 구조(H2/H3)를 그대로 따라가며 각 섹션을 상세하게 정리.
원문에 heading이 없는 경우, 논리적 주제 단위로 나눈다.

### 3. 시사점
원문에 명시된 권장사항, 교훈, 실무 적용 사례를 5-7개 bullet point로 정리.
각 시사점에는 원문에서 인용 가능한 근거를 함께 제시.

## 콘텐츠 추출 (Playwright MCP)

### 전제 조건: Playwright 영구 프로필

이 스킬은 Playwright MCP가 영구 프로필(`~/.playwright-profile`)로 Chrome을 실행합니다.
- 로그인이 필요한 사이트는 **최초 1회** Playwright Chrome에서 로그인하면 세션이 유지됩니다.

### Playwright MCP 서버 확인

콘텐츠 추출 시작 전에 Playwright MCP HTTP 서버가 실행 중인지 확인한다.

```bash
~/bin/playwright-mcp-server.sh
```

실패 시: 에러 보고 후 중단 (progress 파일을 `failed`로 업데이트)

### Step 1: 페이지 접근

`mcp__playwright__browser_navigate`로 URL에 접근.
실패 시: 에러 보고 후 중단 (progress 파일을 `failed`로 업데이트)

### Step 2: 메타데이터 추출

`mcp__playwright__browser_run_code`로 title, author, 이미지 목록 추출.

```javascript
async (page) => {
  const title = await page.title();
  const metadata = await page.evaluate(() => {
    const authorMeta = document.querySelector(
      'meta[name="author"], meta[property="article:author"], meta[name="twitter:creator"]'
    );
    const authorEl = document.querySelector(
      '[rel="author"], .author, .byline, [itemprop="author"]'
    );
    const author = authorMeta?.content || authorEl?.textContent?.trim() || '';
    const images = [...document.querySelectorAll('article img, main img, [role="main"] img, .post-content img, .article-content img, .entry-content img')]
      .map(img => ({ src: img.src, alt: img.alt || '' }))
      .filter(img => img.src && !img.src.startsWith('data:'));
    return { author, images };
  });
  return { title, ...metadata };
}
```

실패 시: snapshot만으로 진행

### Step 3: 본문 추출

`mcp__playwright__browser_snapshot`으로 페이지 콘텐츠를 파일로 저장.
- `filename` 파라미터 사용: `/tmp/article-snapshot-{timestamp}.md`
- 저장된 파일을 Read tool로 읽어서 번역/요약에 사용

### Step 4: 로그인 wall 감지

`~/.claude/auth-registry.json` 파일이 존재하면 로그인 wall을 감지한다.

1. URL 도메인을 auth-registry.json의 키와 매칭
2. 매칭된 사이트가 있으면: snapshot 텍스트에서 `detect_patterns` 검색
3. 패턴이 감지되면: 사용자에게 `login_guide` 메시지 표시, 로그인 완료 후 재시도
4. 미등록 사이트에서 snapshot 본문이 200자 미만이면: 로그인 필요 가능성 안내

### Step 5: 탭 정리

작업 완료 후 `mcp__playwright__browser_close`로 현재 페이지를 닫는다.
브라우저 프로세스는 HTTP 서버가 관리하므로 별도 종료 불필요.

## 이미지 처리

추출된 이미지 목록을 ATTACHMENTS 폴더에 저장하고 문서에 포함.
- 이미지는 하나도 누락 없이 포함
- 다운로드: `curl -sL -o $VAULT_ROOT/ATTACHMENTS/{filename} "{image_url}"`

## 처리 프로세스 요약

1. (백그라운드 모드 시) Progress 파일 생성 → subagent 시작 → 즉시 반환
2. Playwright MCP 서버 확인
3. Playwright로 콘텐츠 추출 (메타데이터 + 본문 + 이미지)
4. 로그인 wall 감지
5. 탭 정리
6. Wikilink 후보 파악 (vis search)
7. 번역/요약 (shared-rules + article 구조, wikilink 포함)
8. 이미지 다운로드
9. 문서 저장 ($VAULT_ROOT/001-INBOX/)
10. Related Notes 추가 (vis search)
11. Atomic Note 후보 추가
12. (백그라운드 모드 시) Progress 파일 업데이트
13. 임시 파일 정리
