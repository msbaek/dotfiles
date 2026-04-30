---
description: audit 결과 기반 대화형 skill 정리 (unused/overlap 결정 기록)
---

<!-- Execution: interactive (main context). frontmatter `model:` 필드는 main context 호출 시 무시되므로 제거. multi-turn 대화 유지를 위해 sub-agent 위임 안 함. -->

최근 audit에서 발견된 unused/overlap 건에 대해 하나씩 결정하고 `SKILLS-DECISIONS.md`에 기록한다.

## Arguments

- `--resume`: 중단된 세션 재개
- `--reset`: 저장된 상태 초기화

## 실행

```bash
~/.claude/bin/skills-curate.py
```

재개:
```bash
~/.claude/bin/skills-curate.py --resume
```

주의: 파일 이동/삭제는 **자동 수행 안 함**. 결정만 기록. `archive`/`delete` 선택 시 실제 파일 작업은 아래 명령을 사용자가 수동 실행.

```bash
# archive 예시
mkdir -p ~/.claude/skills-archive
mv ~/.claude/skills/<name> ~/.claude/skills-archive/

# delete 예시
rm -rf ~/.claude/skills/<name>
```
