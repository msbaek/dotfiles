# Dotfiles Public/Private 분리 계획

## 목표
dotfiles를 public과 private 두 개의 독립적인 repo로 분리하여 민감 정보를 안전하게 관리

## ✅ 완료 상태 (2026-01-18)

| Phase | 상태 | 설명 |
|-------|------|------|
| Phase 1 | ✅ 완료 | BFG로 .gitconfig.user history 정리 |
| Phase 2 | ✅ 완료 | .config/fabric 폴더 삭제 |
| Phase 3 | ✅ 완료 | Private repo 생성 및 파일 이동 |
| Phase 4 | ✅ 완료 | .gitconfig [include] 추가 |
| Phase 5 | ✅ 완료 | 검증 완료 |

## 현재 상태
- Public repo: `~/dotfiles` (GitHub public)
- Private repo: `~/dotfiles-private` (GitHub private) ✅
- 관리 도구: GNU Stow

## 검증 결과 (중요)

**토큰/API 키는 public repo에 노출된 적 없음** - `.gitignore`가 처음부터 보호하고 있었음

| 파일 | Git 추적 | History | 실제 상태 |
|------|----------|---------|-----------|
| `.config/fabric/.env` | X | X | 로컬에만 존재 |
| `.claude/claude_desktop_config.json` | X | X | 로컬에만 존재 |
| `ignored/backup.json` | X | X | 로컬에만 존재 |
| `.config/fabric/patterns/*` | **O** | O | 패턴 파일만 추적 (민감정보 없음) |
| `.gitconfig.user` | X | **O** | **커밋 f7b921a에서 노출** |

## 대상 파일 분류

| 파일 | 조치 | 비고 |
|------|------|------|
| `.claude/claude_desktop_config.json` | Private repo로 이동 | 이미 gitignore |
| `ignored/backup.json` | Private repo로 이동 | 이미 gitignore |
| `.config/fabric/` (폴더 전체) | **삭제** | patterns 파일 커밋 삭제 필요 |
| `.gitconfig.user` | Private repo로 이동 | **BFG로 history 정리 필요** |
| `.env.ktown4u` | Private repo로 이동 | 이미 gitignore |

---

## Phase 1: Git History 정리 (`.gitconfig.user`만)

`.gitconfig.user`가 커밋 `f7b921a`에 존재하므로 BFG로 정리 필요:

```bash
# 1. 백업
cp -r ~/dotfiles ~/dotfiles-backup-$(date +%Y%m%d)

# 2. BFG로 정리
cd /tmp
git clone --mirror ~/dotfiles dotfiles-mirror.git
cd dotfiles-mirror.git
bfg --delete-files .gitconfig.user
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 3. 원본 업데이트
cd ~/dotfiles
git fetch /tmp/dotfiles-mirror.git
git reset --hard FETCH_HEAD
git push origin --force --all
```

---

## Phase 2: .config/fabric 폴더 삭제

patterns 파일들이 git 추적 중이므로 git rm으로 삭제:

```bash
cd ~/dotfiles
git rm -r .config/fabric
git commit -m "chore: remove fabric config (no longer used)"
git push origin main
```

---

## Phase 3: Private Repo 생성

### 3.1 디렉토리 구조

```
~/dotfiles-private/
├── .gitconfig.user                    # Git 사용자 정보
├── .claude/
│   └── claude_desktop_config.json     # MCP 설정
├── ignored/
│   └── backup.json                    # API 키 백업
├── .env.ktown4u                       # ktown4u 환경변수
└── README.md
```

### 3.2 생성 명령

```bash
# 디렉토리 생성
mkdir -p ~/dotfiles-private/.claude
mkdir -p ~/dotfiles-private/ignored

# 파일 복사 (현재 위치에서)
cp ~/.gitconfig.user ~/dotfiles-private/
cp ~/.claude/claude_desktop_config.json ~/dotfiles-private/.claude/
cp ~/dotfiles/ignored/backup.json ~/dotfiles-private/ignored/
cp ~/.env.ktown4u ~/dotfiles-private/

# Git 초기화
cd ~/dotfiles-private
git init
git add .
git commit -m "Initial commit: private dotfiles"

# GitHub private repo 생성 후
git remote add origin git@github.com:msbaek/dotfiles-private.git
git push -u origin main
```

---

## Phase 4: Public Repo 수정

### 4.1 .gitconfig 수정

`[user]` 섹션을 제거하고 `[include]`로 대체:

**수정 전** (line 135-137):
```gitconfig
[user]
	name = Myeongseok Baek
	email = codetemplate@hanmail.net
```

**수정 후**:
```gitconfig
[include]
    path = ~/.gitconfig.user
```

### 4.2 .gitignore 확인

이미 아래 항목들이 .gitignore에 포함되어 있음:
- `.gitconfig.user`
- `.env.*`
- `.claude/claude_desktop_config.json`
- `ignored/`

---

## Phase 5: 검증

### 5.1 Public만으로 동작 확인

```bash
# Stow 재적용
cd ~/dotfiles && stow -R .

# Git 설정 확인 (user 없어야 함)
git config user.name  # 결과 없음

# 셸 시작 (에러 없어야 함)
zsh -i -c 'echo ok'
```

### 5.2 Private 추가 후 확인

```bash
cd ~/dotfiles-private && stow .

# Git 설정 확인
git config user.name  # "Myeongseok Baek"

# 환경변수 확인
source ~/.zshrc
# ktown4u 관련 변수 확인
```

### 5.3 보안 검증

```bash
# gitleaks로 검증
gitleaks detect --source ~/dotfiles --verbose
# "No leaks found" 출력되어야 함
```

---

## 새 머신 셋업 절차

```bash
# 1. Public
git clone https://github.com/msbaek/dotfiles ~/dotfiles
cd ~/dotfiles && stow .
brew bundle

# 2. Private (선택)
git clone git@github.com:msbaek/dotfiles-private ~/dotfiles-private
cd ~/dotfiles-private && stow .
```

---

## Graceful Degradation

| 파일 | Private 없을 때 동작 |
|------|---------------------|
| `.gitconfig.user` | Git include 지시자가 파일 부재 시 자동 무시 |
| `.claude/claude_desktop_config.json` | Claude Desktop 기본 설정으로 동작 |
| `.env.ktown4u` | 이미 조건부 로드: `[[ -f ]] && source` |

---

## 주요 수정 파일

- `/Users/msbaek/dotfiles/.gitconfig` - [user] 섹션 제거, [include] 추가
- `/Users/msbaek/dotfiles/.config/fabric/` - git rm으로 삭제
- `/Users/msbaek/dotfiles/.gitconfig.user` - BFG로 history 정리 후 private repo로 이동
