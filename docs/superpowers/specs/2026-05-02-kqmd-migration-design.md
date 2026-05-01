# K-QMD Migration Design

**Date**: 2026-05-02
**Status**: Draft
**Owner**: msbaek

## Goal (testable)

기존 `qmd` (v1.1.5)를 [K-QMD](https://github.com/jylkim/kqmd) (drop-in replacement)로 교체하여 한국어 의미 검색 품질을 향상한다.

**검증 가능 기준**:
- `qmd --version`이 kqmd 버전 문자열을 반환
- 기존 한국어 자연어 쿼리(예: "보안 취약점 스캔") 검색 결과의 recall이 향상 (qmd-search로 사전/사후 비교 가능)
- 기존 skill (`find-session`, `agf`, `recall`)과 wrapper (`bin/qmd-search`)가 코드 변경 없이 그대로 동작

## Constraints (non-negotiable)

1. **Drop-in 원칙 유지**: kqmd는 `qmd` 명령어를 그대로 노출한다. skill·script·문서의 명령어 호출 패턴은 손대지 않는다.
2. **가역성**: 문제 발생 시 `npm uninstall -g kqmd && brew reinstall qmd`로 즉시 롤백 가능해야 한다.
3. **인덱스 데이터 보존 우선**: 가능하면 기존 인덱스를 그대로 활용하되, 임베딩 모델 불일치 시에만 재생성한다.
4. **메모리 보존**: 미래 세션에서 "qmd가 K-QMD 백엔드"임을 인지할 수 있도록 `MEMORY.md`에 한 줄 기록.
5. **YAGNI**: skill/문서/스크립트의 "qmd" 표현은 갱신하지 않는다 (drop-in이므로 명령어와 일치).

## Failure Conditions

다음 중 하나라도 발생하면 롤백:
- `qmd --version`이 kqmd 버전을 반환하지 않음 (PATH 충돌)
- 기존 `bin/qmd-search` 스크립트가 에러 (예: 서브명령 호환성 문제)
- 기존 skill 호출 시 `qmd query`/`qmd update`/`qmd embed`/`qmd collection list`/`qmd mcp` 중 하나라도 실패
- 인덱스 재생성 후 의미 검색 결과가 의미 있게 악화 (recall 감소)

## Approach: A안 (Drop-in 설치 + α)

### 채택 근거

평가한 3개 옵션:

- **A. qmd 명명 유지** (drop-in 설치만): 변경량 최소, 가역성 최고, 명령어 자연스러움
- **B. kqmd 전면 통일**: 명시성 최고지만 `bin/kqmd-search`에서 `qmd query`를 호출하는 비대칭 발생, 11+개 파일 수정
- **C. 하이브리드**: 명령어는 qmd, 문서·주석은 kqmd 명시

**최종 선택: A + 인덱스 재생성 + 메모리 1줄**.

근거:
1. K-QMD의 강점(Korean-aware search, adaptive ranking, query rescue)은 모두 자동 작동 — 호출 패턴 변경 불요
2. "활용도 강화"라는 추상 가치는 메모리 1줄로 충분히 보존 (skill 11개 갱신 불필요)
3. 미래에 qmd 본가 또는 다른 대체로 돌아갈 때 코드 변경 0줄로 가역
4. YAGNI: 동작에 차이 없는 문서 갱신은 비용

## Components & Changes

### 변경 파일 (2개)

- `~/.claude/projects/-Users-msbaek-dotfiles/memory/reference_kqmd_backend.md` — 신규 메모 파일 (type: reference, K-QMD drop-in 사실 + 설치일 + 임베딩 모델 + 롤백 방법)
- `~/.claude/projects/-Users-msbaek-dotfiles/memory/MEMORY.md` — 인덱스 1줄 추가 (Reference 섹션)

### 무변경 파일 (의도적으로 손대지 않음)

- `bin/qmd-search` — 명령어 호출 그대로 동작
- `.claude/skills/find-session/SKILL.md`, `agf/SKILL.md`, `recall/SKILL.md` — qmd 표기 유지
- `.claude/settings.local.json` — `Bash(qmd-search)` permission 그대로
- `docs/superpowers/specs/2026-03-30-qmd-auto-index-design.md` — 과거 결정 기록 보존

### 시스템 변경

- Homebrew `qmd` 패키지: 제거 검토 (npm 글로벌 `kqmd`와 PATH 충돌 방지)
- npm 글로벌 `kqmd` 패키지: 신규 설치
- qmd 인덱스 (세션 검색용): Qwen3 임베딩으로 재생성

## Data Flow

변경 전:
```
skill → bin/qmd-search → qmd query (Homebrew, 1.1.5) → 인덱스 (이전 임베딩)
```

변경 후:
```
skill → bin/qmd-search → qmd query (npm kqmd) → 인덱스 (Qwen3 임베딩)
                                ↑
                         Korean-aware tokenization,
                         adaptive ranking, query rescue
```

## Execution Steps (high-level — detailed plan은 writing-plans에서)

1. **사전 점검**: 현재 `qmd --version`, 인덱스 위치/크기, `which qmd` 확인
2. **PATH 충돌 처리**: Homebrew qmd가 있다면 `brew unlink qmd` 또는 `brew uninstall qmd`
3. **K-QMD 설치**: `npm install -g kqmd`
4. **검증**: `qmd --version`이 kqmd임을 확인, `which qmd` 경로 점검
5. **인덱스 재생성**: `qmd update && qmd embed` (모델 자동 다운로드 ~2GB+95MB)
6. **smoke test**: 한국어 자연어 쿼리 1-2개로 `qmd-search` 호출, 결과 확인
7. **메모리 기록**: `reference_kqmd_backend.md` 신규 작성 + MEMORY.md Reference 섹션에 인덱스 1줄 추가

## Error Handling

- **PATH 충돌**: Homebrew qmd가 npm 설치보다 먼저 잡히면 `which qmd`로 감지 → 충돌 해결
- **모델 다운로드 실패**: 네트워크 이슈 시 재시도. 첫 실행 시 자동 다운로드되므로 사전 확인용 dry-run 권장
- **인덱스 재생성 실패**: `qmd-search`의 fallback 경로(기존 인덱스로 검색)가 동작하므로 즉시 차단되지 않음
- **smoke test 실패**: README의 한국어 쿼리 패턴(복합어/한영 혼합/긴 쿼리) 중 하나라도 결과 없으면 인덱스 상태 재점검

## Testing

- **사전 baseline**: 변경 전 `qmd-search "보안 취약점"` 결과 N건 기록
- **사후 비교**: 변경 후 동일 쿼리로 결과 비교 (recall 향상 확인)
- **회귀**: `bin/qmd-search`, `find-session` skill, `recall` skill을 한 번씩 호출하여 정상 동작 확인

## Rollback Plan

```bash
npm uninstall -g kqmd
brew install qmd  # 필요 시
qmd update && qmd embed  # 인덱스 원본 임베딩으로 재생성
```

메모리 한 줄 제거 (또는 "롤백됨" 기록).

## Out of Scope

- skill/문서/주석에서 "qmd" → "kqmd" 텍스트 갱신 (YAGNI)
- `bin/qmd-search` → `bin/kqmd-search` 리네임
- skill 트리거 문구 갱신 (한국어 강점 명시 등)
- vis 등 다른 검색 도구와의 통합 변경
- benchmark 자동화 (수동 smoke test로 충분)

## Open Questions

없음 — 사용자 결정 완료.

## References

- K-QMD: https://github.com/jylkim/kqmd
- 기존 qmd 자동 인덱싱 설계: `docs/superpowers/specs/2026-03-30-qmd-auto-index-design.md`
- qmd-search wrapper: `bin/qmd-search`
