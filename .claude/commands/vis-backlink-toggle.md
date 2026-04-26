---
description: vis-backlink (역방향 Related Notes) on/off 토글
argument-hint: [on|off|status]
---

# vis-backlink-toggle

vis-backlink (Obsidian 문서 생성 시 역방향 Related Notes 업데이트) 를 사용자 의지로 활성/비활성화한다.

## 동작

인자 `$ARGUMENTS`:
- `on` 또는 `enable`: `rm -f ~/.claude/state/vis-backlink/.disabled` → "✅ backward Related Notes 활성화"
- `off` 또는 `disable`: `mkdir -p ~/.claude/state/vis-backlink/ && touch ~/.claude/state/vis-backlink/.disabled` → "⏸️  backward Related Notes 비활성화 (재활성화: /vis-backlink-toggle on)"
- `status` 또는 (없음): 현재 ON/OFF 표시 + 사용 가능한 인자 안내

마커 파일이 있으면 backward 스킵 (CLAUDE.md `<when-creating-obsidian-document>` 사전 가드 0번에서 처리). forward (A 자체 Related Notes 추가) 는 영향 없음.

## 출력 예시

```
$ /vis-backlink-toggle off
⏸️  backward Related Notes 비활성화
   마커: ~/.claude/state/vis-backlink/.disabled
   재활성화: /vis-backlink-toggle on
```

## References

- 사전 가드 0번: `~/.claude/CLAUDE.md` `<when-creating-obsidian-document>` → 사전 가드
- 상태 조회: `/vis-backlink-status`
