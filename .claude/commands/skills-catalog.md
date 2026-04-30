---
description: 설치된 모든 Claude Code 스킬 카탈로그를 재생성하고 표시
model: haiku
---

현재 설치된 모든 스킬을 스캔하여 `~/.claude/SKILLS-INDEX.md`를 재생성하고 카테고리별 요약을 표시한다.

## 실행 모델 (필수)

**~/.claude/templates/delegation.md 변형 B 적용**
(model="haiku", run_in_background=false, args=$ARGUMENTS, 옵션=없음)

main context에서 직접 실행 금지.

## 실행

```bash
~/.claude/bin/skills-scan.py
```

출력 파일을 읽어 카테고리별 카운트만 요약해서 사용자에게 보여줘.

```bash
grep "^## " ~/.claude/SKILLS-INDEX.md | wc -l
wc -l ~/.claude/SKILLS-INDEX.md
```

변경 사항 확인:

```bash
~/.claude/bin/skills-scan.py --diff
```

전체 카탈로그를 보고 싶다면 `~/.claude/SKILLS-INDEX.md`를 직접 열어보도록 안내.
