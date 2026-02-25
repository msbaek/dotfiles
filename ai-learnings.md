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
