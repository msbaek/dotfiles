## Ground Rule

- please answer in Korean
- 나에 대한 정보는 ~/git/aboutme/AI-PROFILE.md 에 있어.
  - 이 파일을 참고해서 나에 대한 정보를 파악하고, 나의 스타일에 맞게 답변해줘
- Plan and Review Mode:
  - Before working on any project, always start in plan mode
  - Save plans to .claude/tasks/[taskname].md
  - Break down work into manageable tasks
  - Update the plan as work progresses
- Add a section at the end of your responses labeled "Uncertainty Map," where you describe what you're least confident about, what you may be oversimplifying, and what questions or followups would change your opinion.
- When using APIs, SDKs, libraries, tools, etc., please use the CONTEXT7 MCP
  tool to ensure you know how to use them correctly before proceeding.
- If you don't have enough information to process my request, ask me the
  questions you need before processing my request
  - Ask me if you have any questions for clarification, and continue to do what
    I request.
- If the user's prompt starts with "EP:", then the user wants to enhance the
  prompt. Read the ~/.claude/Prompt-Enhancer.md file and follow the
  guidelines to enhance the user's prompt. Show the user the enhancement and get
  their permission to run it before taking action on the enhanced prompt. The
  enhanced prompts will follow the language of the original prompt (e.g., Korean
  prompt input will output Korean prompt enhancements, English prompt input will
  output English prompt enhancements, etc.)
- If the user's prompt starts with "EP2:", then the user wants to enhance the
  prompt. Read the ~/.claude/Prompt-Enhancer2.md file and follow the
  guidelines to enhance the user's prompt. Show the user the enhancement and get
  their permission to run it before taking action on the enhanced prompt. The
  enhanced prompts will follow the language of the original prompt (e.g., Korean
  prompt input will output Korean prompt enhancements, English prompt input will
  output English prompt enhancements, etc.)
- You run in an environment where ast-grep ('sg') is available; whenever a
  search requires syntax-aware or structural matching, default to
  `sg --lang rust -p '<pattern>'` (or set `--lang` appropriately) and avoid
  falling back to text-only tools like `rg` or `grep` unless I explicitly
  request a plain-text search.
- grep을 사용해야 하는 경우 가급적 rg(https://github.com/BurntSushi/ripgrep)를 사용해주세요
- find를 사용해야 하는 경우 가급적 fd(https://github.com/sharkdp/fd)를 사용해주세요
- 대규모 파일 분석이나 vault 정리 작업 시에는 Task 도구와 sub-agent를 적극
  활용하여 최대한 병렬 처리해서 효율성을 높여주세요
- 반복 가능한 작업을 수행할 때는 향후 재사용을 위해 작업 절차를 문서화해주세요
- 대규모 변경 작업 시에는 처음 몇가지 경우에 대한 샘플을 먼저 보여주고 사용자의
  확인을 받은 후 전체 작업을 진행해주세요
- 다음과 같은 키워드가 포함된 요청을 처리할 때는 관련 url의 정보를 활용해서
  대응해주세요:
  - claude-code"slash commands" -
    <https://docs.anthropic.com/en/docs/claude-code/slash-commands>
  - claude-code "agents", "sub agents" -
    <https://docs.anthropic.com/en/docs/claude-code/sub-agents>
  - tmux-orchestator - <https://github.com/Jedward23/Tmux-Orchestrator>
    - tmux-orchestator는 ~/git/lib/Tmux-Orchestrator/ 에 clone 되어
      있음
- java-guide: 라고 프롬프트를 시작하면 ~/.claude/docs/JAVA-APP-GUIDE.md에 정의된
  내용을 참고해서 내 요청을 처리해줘
  정의되어 있음
- snippet: 으로 프롬프트를 시작하면 ~/.claude/docs/snippets.md에 정의된 config,
  code 등의 snippet을 참고해서 내 요청을 처리해줘

## LEARNING

During doing a task, recognize what information would help you do the task
better and faster next time. For example where is what in the project and save
them to ai-learnings.md file in the project. Use that file to do things better
and faster

## Obsidian Vault 작업 패턴

- Obsidian vault 작업 시 hierarchical tags (#category/subcategory/detail) 형식을
  사용하고, 디렉토리 기반 태그보다 개념 중심 태그를 선호해주세요
- vault의 태그 체계는 5가지 카테고리(Topic, Document Type, Source, Status,
  Project)를 기준으로 적용해주세요
- Zettelkasten 방법론: 000-SLIPBOX (개인 인사이트), 001-INBOX (수집),
  003-RESOURCES (참고자료)
- Hierarchical tags: #category/subcategory/detail 형식 사용
- 파일 분석 시 중복 파일("사본"), 빈 폴더, 임시 파일 체크
- vault-analysis/ 폴더에 분석 결과 저장

## Vault Intelligence 사용 시

사용자의 요청 처리를 위해 vault 검색이 필요한 경우:

### 시스템 위치
- vault-intelligence: `~/git/vault-intelligence/`
- vault 경로: `~/DocumentsLocal/msbaek_vault/`

### CLI 사용법
**⚠️ 중요: ~/git/vault-intelligence/CLAUDE.md의 "CLI 빠른 참조" 섹션을 반드시 참조하세요!**

```bash
# 기본 검색 (올바른 옵션 사용)
cd ~/git/vault-intelligence
python -m src search --query "검색어" --search-method hybrid --top-k 10

# 자주 실수하는 옵션들 주의:
# ❌ --method (X)      → ✅ --search-method (O)
# ❌ --k (X)           → ✅ --top-k (O)
# ❌ --output-file (X) → ✅ --output (O)
# ❌ --reranking (X)   → ✅ --rerank (O)
```

### 검색 방법 선택
- `--search-method semantic`: 의미적 검색 (개념 기반)
- `--search-method keyword`: 키워드 검색 (정확한 매칭)
- `--search-method hybrid`: 하이브리드 검색 (기본값, 권장)
- `--search-method colbert`: ColBERT 토큰 검색 (정밀 매칭)

### 고급 옵션
- `--rerank`: 재순위화 (정확도 향상)
- `--expand`: 쿼리 확장 (동의어 + HyDE, 포괄성 향상)
- `--with-centrality`: 중심성 점수 반영

### 상세 가이드
- CLI 빠른 참조: `~/git/vault-intelligence/CLAUDE.md`
- 사용자 가이드: `~/git/vault-intelligence/docs/USER_GUIDE.md`
- 실전 예제: `~/git/vault-intelligence/docs/EXAMPLES.md`

## Vault 태그 체계

- vault_root vault-analysus/improved-hierarchical-tags-guide.md 참조
  - 디렉토리 기반 태그(resources/, slipbox/) 제거
  - development/ prefix 제거 (대부분 개발 관련)

## 파일 처리 오류 시

- 읽기 오류 파일은 별도 문서(UNPROCESSED-FILES.md)에 기록
- 오류 원인: 특수문자 인코딩, 심볼릭 링크, 권한 문제 등
- Canvas 파일(.canvas)과 이미지 파일은 태그 적용 대상에서 제외
