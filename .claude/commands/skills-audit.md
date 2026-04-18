---
description: 최근 N일 skill 사용량 감사 리포트 (top/unused/overlap/stale)
model: haiku
---

스킬 사용 통계를 리포트한다.

## Arguments

- `$1`: lookback days (기본 30). 숫자만 지정. 예: `/skills-audit 60`
- `--unused`: unused 섹션만 표시
- `--overlap 0.8`: overlap similarity 임계값 조정 (기본 0.7)

## 실행

```bash
~/.claude/bin/skills-audit.py --days "${1:-30}"
```

`--unused` 플래그:
```bash
~/.claude/bin/skills-audit.py --days "${1:-30}" --unused-only
```

`--overlap` 플래그:
```bash
~/.claude/bin/skills-audit.py --days "${1:-30}" --overlap-threshold "${2:-0.7}"
```

결과를 사용자에게 보여주고, 정리할 의향이 있으면 `/skills-curate` 실행을 제안.
