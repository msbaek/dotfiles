---
argument-hint: "[url]"
description: "기술 문서 URL → 백그라운드로 번역/정리 → obsidian 문서 생성"
color: yellow
---

# article summarize - $ARGUMENTS

기술 문서 URL을 받아 **백그라운드**로 번역/정리하여 Obsidian 문서를 생성합니다.

## 실행 모드 판단

**이 스킬이 직접 호출된 경우 (사용자가 메인 세션에서 `/obsidian:summarize-article URL` 실행):**
→ **백그라운드 모드**로 실행

**이 스킬이 subagent 내부에서 호출된 경우 (batch-summarize-urls 등):**
→ **동기 모드**로 실행

## 백그라운드 모드 (직접 호출 시)

### Step 1: Progress 파일 생성

`.claude/article-progress/` 디렉토리에 진행 상황 파일을 생성합니다.
파일명: `YYYYMMDD-HHMMSS-{url-slug}.json`

```json
{
  "url": "$ARGUMENTS",
  "status": "processing",
  "started_at": "현재시간 ISO-8601",
  "completed_at": null,
  "output_file": null,
  "error": null
}
```

### Step 2: 백그라운드 subagent 시작

Task tool을 사용하여 백그라운드 subagent를 시작합니다:

- `subagent_type`: "general-purpose"
- `run_in_background`: true
- `description`: "Summarize: {URL 도메인/경로 일부}"
- `prompt`: 아래 동기 모드 프로세스 전체를 포함하되, 다음을 추가:
  - progress 파일 경로를 전달
  - 작업 완료 후 progress 파일을 completed로 업데이트하도록 지시
  - 실패 시 progress 파일을 failed로 업데이트하도록 지시

### Step 3: 사용자에게 알림 후 즉시 반환

```
백그라운드 작업 시작됨:
- URL: $ARGUMENTS
- Progress: .claude/article-progress/{파일명}.json
- 완료되면 자동으로 알려드립니다.
```

## 동기 모드 (subagent에서 호출 시 / 백그라운드 subagent 내부)

### 전제 조건: Playwright 영구 프로필

이 스킬은 Playwright MCP가 영구 프로필(`~/.playwright-profile`)로 Chrome을 실행합니다.
- 로그인이 필요한 사이트는 **최초 1회** Playwright Chrome에서 로그인하면 세션이 유지됩니다.
- 로그인 방법: `mcp__playwright__browser_navigate`로 사이트 접근 → 수동 로그인 → 이후 자동 유지.

### Step 1: 콘텐츠 추출 (Playwright MCP)

Playwright MCP 도구를 사용하여 콘텐츠를 추출합니다.

#### 1단계: 페이지 접근

`mcp__playwright__browser_navigate`로 URL에 접근합니다.

- URL: `$ARGUMENTS`
- 실패 시: 에러 보고 후 중단 (progress 파일을 `failed`로 업데이트)

#### 2단계: 메타데이터 추출

`mcp__playwright__browser_run_code`로 title, author, 이미지 목록을 추출합니다.

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

- 실패 시: snapshot만으로 진행 (title은 snapshot의 `heading [level=1]` 텍스트에서 파싱, author는 빈 문자열)

#### 3단계: 본문 추출

`mcp__playwright__browser_snapshot`으로 페이지 콘텐츠를 파일로 저장합니다.

- `filename` 파라미터 사용: `/tmp/article-snapshot-{timestamp}.md`
- 저장된 파일을 Read tool로 읽어서 번역/요약에 사용
- 실패 시: 에러 보고 후 중단

#### 3.5단계: 로그인 wall 감지

`~/.claude/auth-registry.json` 파일이 존재하면 로그인 wall을 감지합니다.

1. URL 도메인을 auth-registry.json의 키와 매칭
2. 매칭된 사이트가 있으면: snapshot 텍스트에서 `detect_patterns` 검색
3. 패턴이 감지되면:
   - 사용자에게 `login_guide` 메시지 표시
   - 사용자가 로그인 완료를 알리면 동일 URL로 재시도 (1단계부터)
   - 재시도 후에도 실패하면 에러 보고
4. 미등록 사이트에서 snapshot 본문이 비정상적으로 짧으면 (200자 미만):
   - "로그인이 필요할 수 있습니다. Dia에서 해당 사이트에 로그인 후 다시 시도해주세요."
   - "이 사이트의 로그인 패턴을 auth-registry.json에 추가할까요?" 제안
   - 사용자가 승인하면: 현재 snapshot에서 wall 패턴 후보를 추출하여 레지스트리에 추가

#### 4단계: 브라우저 정리

`mcp__playwright__browser_close`로 페이지를 닫습니다.

### Step 2: 번역 및 요약

추출된 콘텐츠를 아래 규칙(`## 문서 번역 및 요약 규칙`)에 따라 정리하여 yaml frontmatter를 포함한 obsidian 파일로 저장합니다.

- 저장 경로: `$VAULT_ROOT/001-INBOX/`
- hierarchical tagging 규칙: `~/.claude/commands/obsidian/add-tag.md` 준수

### Step 3: 이미지 처리

추출된 이미지 목록(`images[]`)을 ATTACHMENTS 폴더에 저장하고, Obsidian 문서에 포함시킵니다.

- ATTACHMENTS 경로: `$VAULT_ROOT/ATTACHMENTS/`
- **이미지는 하나도 누락 없이 포함**되어야 합니다
- 이미지 다운로드에는 bash curl을 사용합니다:
  ```bash
  curl -sL -o $VAULT_ROOT/ATTACHMENTS/{filename} "{image_url}"
  ```

### Step 4: Progress 파일 업데이트 (백그라운드 모드 시)

progress 파일 경로가 전달된 경우, 작업 완료/실패 시 업데이트합니다:

성공 시:
```json
{
  "url": "...",
  "status": "completed",
  "started_at": "...",
  "completed_at": "현재시간 ISO-8601",
  "output_file": "001-INBOX/문서제목.md",
  "error": null
}
```

실패 시:
```json
{
  "url": "...",
  "status": "failed",
  "started_at": "...",
  "completed_at": "현재시간 ISO-8601",
  "output_file": null,
  "error": "에러 메시지"
}
```

## yaml frontmatter 예시

```yaml
id: 10 Essential Software Design Patterns used in Java Core Libraries
aliases: Java 코어 라이브러리에서 사용되는 10가지 필수 소프트웨어 디자인 패턴
tags:
  - patterns/design-patterns/java-implementation
  - patterns/creational/factory-singleton-builder
  - patterns/structural/adapter-facade-proxy
  - patterns/behavioral/observer-strategy-template
  - java/core-libraries/design-patterns
  - frameworks/java/standard-library
  - development/practices/object-oriented-design
  - architecture/patterns/gof-patterns
author: ali-zeynalli
created_at: 2025-09-04 11:39
related: []
source: https://azeynalli1990.medium.com/10-essential-software-design-patterns-used-in-java-core-libraries-bb8156ae279b
```

- id: 문서에서 발견한 제목 (Playwright MCP에서 추출한 title 사용)
- aliases: 문서에서 발견한 제목의 한국어 번역
- author: 문서에서 발견한 작성자 (Playwright MCP에서 추출한 author 사용). 이름은 다 소문자, 공백은 '-'로 변경
- created_at: obsidian 파일 생성 시점
- source: 문서 url

## 문서 번역 및 요약 규칙

```
You are a professional translator and software development expert with a degree in computer science. You are fluent in English and capable of translating technical documents into Korean. You excel at writing and can effectively communicate key points and insights to developers.

Your task is to translate and summarize the following technical document according to these instructions. Please provide a detailed summary of approximately 4000 characters, using professional terminology from a software development perspective. Do not add any information that is not present in the original document.

Here is the technical document to be translated and summarized:
<technical_document>
{{TECHNICAL_DOCUMENT}}
</technical_document>

Translation requirements:
1. Translate the input text into Korean.
2. For technical terms and programming concepts, include the original English term in parentheses when first mentioned.
   - Include as many original terms as possible.
3. Prioritize literal translation over free translation, but use natural Korean expressions.
4. Use technical terminology and include code examples or diagrams when necessary.
5. Explicitly mark any uncertain parts.

Summary structure:

## 1. Highlights/Summary: Summarize the entire content in 2-3 paragraphs.

## 2. Detailed Summary: Divide the content into sections based on subheadings. For each section, provide a detailed summary in 2-3 paragraphs.

## 3. Conclusion and Personal View:
   - Summarize the entire content in 5-10 statements.
   - Provide your perspective on why this information is important.

Important considerations:
- The target audience is a Korean software developer with over 25 years of experience, who obtained a Computer Science degree and a master's degree in Korea, specializing in object-oriented analysis & design and software architecture.
- They have extensive experience in developing and operating various services and products.
- They are particularly interested in sustainable software system development, OOP, developer capability enhancement, Java, TDD, Design Patterns, Refactoring, DDD, Clean Code, Architecture (MSA, Modulith, Layered, Hexagonal, vertical slicing), Code Review, Agile (Lean) Development, Spring Boot, building development organizations, improving development culture, developer growth, and coaching.
- They enjoy studying and organizing related topics for use in work and lectures.
- They cannot quickly read English text or watch English videos.

Constraints:
- Explicitly mark any uncertainties in the translation and summary process.
- Use accurate and professional terminology as much as possible.
- Balance the content of each section to avoid being too short or too long.
- Include actual code examples or pseudocode to make explanations more concrete.
- Use analogies or examples to explain complex concepts in an easy-to-understand manner.
- Write in artifact format
- If you don't know certain information, clearly state that you don't know.
- Self-verify the final information before answering.
- Include all example codes in the document without omission.

Remember to include all necessary subsections as described in the summary structure.
```

## 진행 상황 모니터링

메인 세션에서 현재 진행 중인 백그라운드 작업을 확인하려면:

`.claude/article-progress/` 폴더의 JSON 파일들을 읽어서 상태를 보고합니다:
- `processing`: "처리 중: URL"
- `completed`: "완료: URL → 파일경로"
- `failed`: "실패: URL (에러메시지)"
