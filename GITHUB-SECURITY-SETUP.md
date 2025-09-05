# GitHub Secret Scanning 설정 가이드

이 문서는 dotfiles 저장소를 GitHub에 업로드한 후 보안 기능을 활성화하는 방법을 설명합니다.

## 🔧 필수 설정

### 1. Secret Scanning 활성화

**Public 저장소는 자동으로 활성화**되지만, 추가 보안을 위해 다음을 확인하세요:

1. GitHub 저장소 → **Settings** 탭
2. **Security & analysis** 섹션
3. **Secret scanning** 확인:
   - ✅ Secret scanning: **Enabled** (기본 활성화)
   - ✅ Push protection: **Enable** 버튼 클릭 ⭐ **중요**

### 2. Push Protection 설정

Push protection은 실수로 secret을 푸시하는 것을 방지합니다:

```
Settings > Security & analysis > Secret scanning > Push protection
[Enable] 버튼 클릭
```

### 3. 추가 보안 기능 (권장)

같은 Security & analysis 페이지에서:

- ✅ **Dependabot alerts**: Enable (의존성 취약점)
- ✅ **Dependabot security updates**: Enable (자동 보안 업데이트)
- ✅ **Code scanning**: Set up (코드 취약점 스캔)

## 🚨 Secret 감지 시 대응

### Push가 차단된 경우:

1. **당황하지 말고** 차단 메시지를 자세히 읽기
2. 해당 파일에서 민감한 정보 제거:
   ```bash
   # 파일에서 secret 제거
   vim filename.ext

   # 변경사항 스테이징
   git add filename.ext

   # 다시 커밋
   git commit --amend
   ```

3. 다시 푸시 시도

### 이미 푸시된 Secret 발견 시:

1. **즉시 해당 API 키/토큰 무효화**
2. Git 히스토리에서 제거:
   ```bash
   # git-filter-repo 사용 (권장)
   pip install git-filter-repo
   git filter-repo --path filename.ext --invert-paths

   # 강제 푸시
   git push --force-with-lease
   ```

## 📋 체크리스트

저장소 설정 완료 후 확인:

- [ ] Secret scanning 활성화됨
- [ ] **Push protection 활성화됨** ⭐
- [ ] Dependabot alerts 활성화됨
- [ ] 첫 푸시 후 Security 탭에서 알림 없음 확인
- [ ] Pre-commit 훅이 로컬에서 정상 작동
- [ ] `.secrets.baseline` 파일 생성됨

## ⚙️ 로컬 Pre-commit 설정

GitHub 업로드 전에 로컬에서도 보안 체크:

```bash
# 1. 도구 설치
pip install pre-commit detect-secrets

# 2. 훅 설치
pre-commit install

# 3. 베이스라인 생성
detect-secrets scan --baseline .secrets.baseline

# 4. 첫 실행 (모든 파일 체크)
pre-commit run --all-files
```

## 🔍 정기 모니터링

### GitHub에서 확인할 항목:

1. **매주**: Security 탭 → Secret scanning alerts
2. **매월**: Dependabot alerts 확인 및 업데이트
3. **분기별**: Security policy 검토 및 업데이트

### 알림 설정:

`Settings > Notifications > Security alerts`에서:
- ✅ Secret scanning alerts
- ✅ Dependabot alerts
- ✅ Security vulnerabilities

## 🆘 문제 해결

### 자주 발생하는 문제:

1. **False positive 알림**:
   - `.secrets.baseline`에 예외 추가
   - `--update-baseline` 플래그 사용

2. **Pre-commit 실패**:
   ```bash
   # 특정 훅 건너뛰기 (임시)
   SKIP=detect-secrets git commit -m "message"

   # 훅 업데이트
   pre-commit autoupdate
   ```

3. **Push protection 우회** (정말 필요한 경우만):
   ```bash
   git push --no-verify
   ```
   ⚠️ **주의**: 이 명령어는 모든 보안 체크를 건너뛸니다.

## 📞 추가 도움

- [GitHub Secret Scanning 문서](https://docs.github.com/en/code-security/secret-scanning)
- [Pre-commit 가이드](https://pre-commit.com/)
- [detect-secrets 문서](https://github.com/Yelp/detect-secrets)

---

**중요**: 이 설정들은 실수를 방지하는 도구일 뿐입니다. 가장 중요한 것은 애초에 민감한 정보를 커밋하지 않는 것입니다.
