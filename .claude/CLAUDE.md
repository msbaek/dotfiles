## Ground Rule

### 행동 원칙 (Action Principles)
사용자의 명시적 요청이 있을 때만 구현/변경을 수행. 불명확할 때는 조사와 추천을 먼저.

<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>

### 코드 탐색 (Code Investigation)
코드를 읽지 않고 추측하지 말 것. 파일 참조 시 반드시 열어서 확인 후 답변.

<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
ALWAYS read and understand relevant files before proposing code edits. Be rigorous and persistent in searching code for key facts. Thoroughly review the style, conventions, and abstractions of the codebase before implementing new features or abstractions.
</investigate_before_answering>

### 품질 관리 (Quality Control)
요청된 것만 구현. 과잉 엔지니어링, 하드코딩, 불필요한 파일 생성 금지.

<avoid_overengineering>
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.
Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.
Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use feature flags or backwards-compatibility shims when you can just change the code.
Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task—three similar lines of code is better than a premature abstraction.
</avoid_overengineering>

<avoid_hardcoding_for_tests>
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.
Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.
If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
</avoid_hardcoding_for_tests>

<reduce_file_creation>
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
</reduce_file_creation>

### 장기 작업 (Long-running Tasks)
컨텍스트 한계와 관계없이 작업 완료. 상태는 JSON, progress.txt, git으로 관리.

<context_persistence>
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
</context_persistence>

<state_management>
Use structured formats (JSON) for tracking structured information like test results or task status.
Use unstructured text (progress.txt) for freeform progress notes and general context.
Use git for state tracking - it provides a log of what's been done and checkpoints that can be restored.
Focus on incremental progress - keep track of progress and work on a few things at a time rather than attempting everything at once.
</state_management>

### 협업 패턴 (Collaboration Patterns)
리서치, 서브에이전트, 병렬 도구 호출을 활용하여 효율적으로 작업.

<research_and_information_gathering>
For optimal research results:
1. Provide clear success criteria: Define what constitutes a successful answer to your research question.
2. Encourage source verification: Verify information across multiple sources.
3. For complex research tasks, use a structured approach: Search for information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down complex research tasks systematically.
</research_and_information_gathering>

<subagent_orchestration>
To take advantage of subagent orchestration:
1. Ensure well-defined subagent tools: Have subagent tools available and described in tool definitions.
2. Let Claude orchestrate naturally: Claude will delegate appropriately without explicit instruction.
3. Adjust conservativeness if needed: Only delegate to subagents when the task clearly benefits from a separate agent with a new context window.
</subagent_orchestration>

<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>

### 언어 및 소통
- 한국어로 답변
- 나에 대한 정보: ~/git/aboutme/AI-PROFILE.md 참조
- 응답 끝에 "Uncertainty Map" 섹션 추가 (확신이 낮은 부분, 단순화한 부분, 추가 질문 시 의견이 바뀔 수 있는 부분)

### 작업 패턴
- 프로젝트 시작 전 항상 plan mode로 시작
- 계획은 .claude/tasks/[taskname].md에 저장
- 작업 진행에 따라 계획 업데이트

### 정보 부족 시
- 충분한 정보가 없으면 먼저 질문
- API/SDK/라이브러리 사용 시 CONTEXT7 MCP 도구로 확인

## 도구 사용

### 검색/탐색 도구

| 작업 | 사용할 도구 | 이유 |
|------|------------|------|
| 구문 인식 검색 | `sg --lang <언어> -p '<패턴>'` | 구조적 매칭에 최적화 |
| 텍스트 검색 | `rg` (ripgrep) | grep보다 빠르고 .gitignore 자동 존중 |
| 파일 찾기 | `fd` | find보다 빠르고 직관적 |

### 병렬 처리
대규모 파일 분석이나 vault 정리 작업 시 Task 도구와 sub-agent를 적극 활용하여 병렬 처리

### 대규모 변경 시
처음 몇 가지 샘플을 먼저 보여주고 확인 받은 후 전체 작업 진행

### 반복 작업 시
향후 재사용을 위해 작업 절차 문서화

## LEARNING

작업 중 다음 번에 더 빠르게 작업할 수 있는 정보 발견 시 프로젝트의 ai-learnings.md에 기록

## Obsidian Vault 작업

### 경로
- vault-intelligence: `~/git/vault-intelligence/`
- vault: `~/DocumentsLocal/msbaek_vault/`

### 태그 체계
- Hierarchical tags: `#category/subcategory/detail`
- 5가지 카테고리: Topic, Document Type, Source, Status, Project
- Zettelkasten: 000-SLIPBOX (개인 인사이트), 001-INBOX (수집), 003-RESOURCES (참고자료)
- 상세 가이드: vault_root/vault-analysis/improved-hierarchical-tags-guide.md

### vault-intelligence CLI

```bash
cd ~/git/vault-intelligence
python -m src search --query "검색어" --search-method hybrid --top-k 10
```

**주요 옵션:**
- `--search-method`: semantic | keyword | hybrid (권장) | colbert
- `--rerank`: 재순위화로 정확도 향상
- `--expand`: 쿼리 확장 (동의어 + HyDE)

**자주 실수하는 옵션:**
| 잘못된 옵션 | 올바른 옵션 |
|------------|------------|
| `--method` | `--search-method` |
| `--k` | `--top-k` |
| `--output-file` | `--output` |
| `--reranking` | `--rerank` |

**상세 가이드:** ~/git/vault-intelligence/CLAUDE.md

### 파일 처리 오류 시
- 읽기 오류 파일은 UNPROCESSED-FILES.md에 기록
- Canvas 파일(.canvas)과 이미지 파일은 태그 적용 제외
