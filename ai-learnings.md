# AI Learnings

## Playwright MCP 설정 (2026-02-25)

### 플러그인 vs 수동 MCP 서버 충돌
**문제:** `enabledPlugins: false`로도 `mcp__plugin_playwright_playwright__*` 도구가 여전히 로드됨.
**해결:** 플러그인 항목 자체를 삭제. 스킬에서 `mcp__playwright__*` 명시.

### CDP 연결 한계
**문제:** Dia 브라우저 CDP는 WebSocket 연결은 성공하지만 Playwright `connectOverCDP`에서 타임아웃.
- 직접 CDP 명령 (Browser.getVersion, Target.createTarget)은 정상
- Playwright의 고수준 `connectOverCDP` wrapper가 Dia와 호환 안됨
**결론:** Chromium fork 브라우저의 CDP 호환성은 보장되지 않음. Playwright MCP는 자체 Chrome 사용이 안정적.

### 영구 프로필 방식 (최종 채택)
**설정:** `playwright-config.json`에서 `browser.userDataDir` 지정 → 세션 간 쿠키/로그인 유지.
- 최초 1회 로그인 후 계속 사용 가능
- CDP 불필요, Dia 불필요

### 규칙
- MCP 플러그인과 수동 MCP 서버 중복 시: 플러그인 항목 완전 삭제
- Playwright MCP 인증 사이트 접근: `userDataDir` 영구 프로필 사용
- API/SDK 설정: CONTEXT7 MCP로 공식 문서 확인 후 적용
- MCP 설정 변경 후 반드시 수동 테스트 (MCP protocol 직접 호출로 검증 가능)

## Brewfile 패키지 의존성 주의 (2026-03-03)

### autojump은 oh-my-zsh가 사용
**문제:** Brewfile 정리 시 autojump을 제거했으나, oh-my-zsh의 autojump 플러그인이 의존.
**규칙:** 패키지 제거 전 oh-my-zsh 플러그인 목록(`.zshrc`의 `plugins=()`)과 교차 확인할 것.

## Homebrew 패키지 식별 오류 (2026-03-06)

### 문제
tw93/mole(macOS 시스템 청소/최적화 도구)을 davrodpin/mole(SSH 터널링 도구)과 혼동하여 "ssh -L 대체" 사유로 잘못 제거함.

### 규칙
- 패키지 제거 전 반드시 GitHub 저장소를 확인하여 실제 용도를 검증할 것
- 동명의 패키지가 여러 개 존재할 수 있으므로, tap/author까지 확인할 것

## Brewfile pre-commit hook 충돌 (2026-03-02)

### 문제
pre-commit hook `update-brewfile.sh`가 `brew bundle dump --force`를 실행하여 매 커밋 시 Brewfile을 현재 설치 상태로 덮어씀. 수동 편집(카테고리화, 정리)이 모두 원복됨.

### 해결
- Brewfile은 hook이 자동 관리하도록 두고, 카테고리화된 큐레이션 파일을 `docs/brewfile-curated.md`로 분리
- 패키지 제거는 Brewfile 편집이 아닌 `brew uninstall` 실행 → 다음 커밋 시 hook이 Brewfile 자동 업데이트

### 규칙
- Brewfile을 직접 편집하지 말 것 (hook이 덮어씀)
- 패키지 추가/제거는 `brew install`/`brew uninstall` 후 커밋
- 카테고리화, 문서화 등 부가 정보는 별도 파일(docs/)에 보관
