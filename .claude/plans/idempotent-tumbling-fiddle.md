# Git 커밋 메시지 한글 복원 계획

## 문제 상황

5개의 커밋 메시지에서 한글이 Rust 스타일 유니코드 이스케이프(`\u{XXXX}`)와 중간점(`·`)으로 깨져있음.

## 영향받은 커밋 (오래된 순)

| SHA | 복원된 메시지 |
|-----|--------------|
| `eaef66a` | `fix: JitPack 배포 설정 수정` |
| `185ab49` | `fix: JitPack 배포 설정 단순화` |
| `e22bf79` | `feat: GitHub Packages 배포 설정 추가` |
| `c4c05f3` | `feat(masking): Spring Profile 기반 마스킹 활성화/비활성화 제어` |
| `ce0eafa` | `docs: 마스킹 라이브러리 사용 가이드 및 CLAUDE.md 추가` |

## 선택된 방식: git filter-repo (자동화) ✅

`git-filter-repo`가 이미 설치되어 있음 (`/Users/msbaek/.pyenv/shims/git-filter-repo`)

### Step 1: 백업 브랜치 생성
```bash
git branch backup-before-fix
```

### Step 2: git filter-repo로 모든 커밋 메시지 자동 수정
```bash
git filter-repo --message-callback '
import re

def decode_rust_unicode(msg):
    def replace(match):
        code = int(match.group(1), 16)
        return bytes([code >> 8, code & 0xff]) if code > 255 else bytes([code])
    # Rust style \u{XXXX} -> unicode
    result = re.sub(rb"\\\\u\\{([0-9a-fA-F]+)\\}",
                    lambda m: chr(int(m.group(1), 16)).encode("utf-8"),
                    msg)
    # Middle dot (·) -> space
    result = result.replace(b"\\xc2\\xb7", b" ")
    # Line separator (␊) -> newline
    result = result.replace(b"\\xe2\\x90\\x8a", b"\\n")
    return result

return decode_rust_unicode(message)
' --force
```

### Step 3: Remote 재설정 및 Force Push
```bash
git remote add origin git@github.com:ktown4u/ktown4u-masking.git
git push --force-with-lease origin main
```

### Step 4: 정리
```bash
git branch -d backup-before-fix
```

## Uncertainty Map

- **협업자 존재 여부**: force push 전 확인 필요 - 다른 개발자가 이 브랜치를 사용 중이라면 사전 공지 필요
- **CI/CD 영향**: 푸시 후 파이프라인 재실행 가능성
- **filter-repo 콜백 정확성**: 실행 전 dry-run 또는 백업으로 검증 필요
