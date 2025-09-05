# Security Policy

이 저장소는 개인 dotfiles 설정을 포함하고 있으며, public 저장소로 안전하게 공개하기 위해 다음 보안 정책을 준수합니다.

## 🔒 보안 원칙

### 1. 민감한 정보 제외
- **API 키, 토큰, 비밀번호**: 모든 실제 값은 `.env.*` 파일에 저장하고 `.gitignore`에 제외
- **SSH 키 및 인증서**: `.ssh/`, `.pem`, `.key` 등 모든 인증 파일 제외
- **개인 인증 정보**: `.gitconfig.user`, 실제 서버 설정 등 제외

### 2. 템플릿 제공
- `*.example` 파일로 설정 템플릿 제공
- 실제 값은 placeholder로 대체
- 사용법과 설정 가이드 포함

### 3. 경로 일반화
- 하드코딩된 개인 경로(`/Users/msbaek`) 대신 `$HOME`, `~` 사용
- 환경변수 활용으로 이식성 향상

## 🛡️ 보안 도구

### Pre-commit 훅
다음 도구들이 자동으로 민감한 정보 커밋을 방지합니다:

```bash
# 설치
pip install pre-commit detect-secrets
pre-commit install

# 실행
detect-secrets scan --baseline .secrets.baseline
```

### GitHub Secret Scanning
- Push protection 활성화로 실수 방지
- Secret scanning 자동 감지
- Dependabot 보안 알림

## ⚠️ 현재 노출된 정보

### 개인정보 (낮은 위험)
- **이름**: Myeongseok Baek (`.gitconfig`)
- **이메일**: codetemplate@hanmail.net
- **회사 정보**: ktown4u 프로젝트 참조

이 정보들은 일반적으로 공개되어도 보안상 큰 문제가 없는 수준입니다.

## 🚨 금지사항

커밋하지 말아야 할 파일들:
- `.env.ktown4u` (실제 환경변수)
- `.gitconfig.user` (실제 사용자 정보)
- `.ssh/config` (실제 SSH 설정)
- `*.pem`, `*.key`, `*.p12` (인증 파일)
- 실제 API 키나 토큰이 포함된 파일

## 📋 보안 체크리스트

새로운 설정 파일 추가 시 확인사항:

- [ ] 민감한 정보가 포함되어 있지 않은가?
- [ ] 하드코딩된 경로 대신 환경변수를 사용했는가?
- [ ] 필요시 `.example` 템플릿을 제공했는가?
- [ ] `.gitignore`에 실제 설정 파일을 추가했는가?
- [ ] pre-commit 훅이 통과하는가?

## 🔍 정기 감사

월 1회 다음 항목을 점검합니다:
- 새로 추가된 설정 파일의 보안성 검토
- `.gitignore` 패턴의 적절성 확인
- 외부 종속성의 보안 업데이트 확인

## 📞 보안 문제 신고

보안 관련 문제를 발견하면:
1. **즉시 개인 채널로 연락** (공개 이슈 생성 금지)
2. 문제의 상세 설명과 영향 범위 포함
3. 가능한 해결책 제안

---

이 정책은 dotfiles의 공개성과 보안성의 균형을 맞추기 위해 지속적으로 업데이트됩니다.
