# vault-intelligence 문서 재구조화 계획

## 진행 상황 (2026-01-12 완료)

| Phase | 상태 | 내용 |
|-------|------|------|
| Phase 1 | ✅ 완료 | 폴더 구조 생성 (docs/user, docs/dev/archive, archive/ai-practice) |
| Phase 2 | ✅ 완료 | 기존 문서 이동 |
| Phase 3 | ✅ 완료 | 신규 문서 작성 (AI-PRACTICE-SUMMARY.md, DEVELOPMENT.md) |
| Phase 4 | ✅ 완료 | README.md 문서 인덱스 추가 |
| Phase 5 | ✅ 완료 | EXAMPLES.md 확장 (실제 활용 사례 4개 추가) |
| Phase 6 | ✅ 완료 | CHANGELOG.md Keep a Changelog 형식 전환 |
| Phase 7 | ✅ 완료 | 정리 및 검증 (samples/README.md 삭제, 모든 링크 검증) |

### 🎉 모든 작업 완료!
커밋 준비 완료. 아래 명령어로 변경사항을 커밋하세요:
```bash
git add -A && git commit -m "docs: 문서 재구조화 완료 (Phase 1-7)"
```

---

## 목표
1. vault-intelligence로 수행한 작업 내역을 문서에 반영
2. 방만한 문서들을 MOC/Index로 정리하여 정보 접근성 향상

---

## 사용자 선택 요약

| 항목 | 선택 |
|------|------|
| 상세 수준 | 기능 타임라인 + 사용 사례 중심 |
| ai-practice 처리 | archive/로 이동 + 요약 문서 생성 |
| docs 구조 | user/ + dev/로 2분화 |
| MOC 형태 | README.md에 '문서 인덱스' 섹션 통합 |
| MOC 분류 | 기능별 분류 |
| samples 처리 | EXAMPLES.md에 핵심 예제 통합 |
| 개발 과정 | DEVELOPMENT.md 신규 생성 |
| 임시 파일 | docs/dev/archive/로 이동 |
| CLAUDE.md 독자 | AI 우선 |
| CHANGELOG | 날짜 기준으로 전환 |
| cc-logs | 유지 |

---

## 변경 파일 목록

### 신규 생성
1. **docs/AI-PRACTICE-SUMMARY.md** - 2,319개 AI 기법 요약
2. **DEVELOPMENT.md** - Phase 1-9 개발 과정, Claude Code 활용 패턴

### 구조 변경
3. **docs/** 폴더 재구조화:
   ```
   docs/
   ├── user/                      # 사용자 문서
   │   ├── README.md              # docs MOC
   │   ├── QUICK_START.md
   │   ├── USER_GUIDE.md
   │   ├── EXAMPLES.md            # samples 통합
   │   └── TROUBLESHOOTING.md
   ├── dev/                       # 개발자 문서
   │   ├── embedding-upgrade-plan.md
   │   ├── multi-document-summarization-prd.md
   │   ├── phase9-implementation-plan.md
   │   ├── extract-dup-to-config.md
   │   ├── todo-embedding-upgrade.md
   │   └── archive/               # 완료된 계획
   │       ├── ColBERT-Bug-Fix-Plan.md
   │       └── test_driven_design.md
   └── DOCUMENTATION_AUDIT_REPORT.md
   ```

4. **archive/** 폴더 생성:
   ```
   archive/
   └── ai-practice/              # plans/에서 이동
       ├── ai-practice-files.md
       ├── ai-practice-plan.md
       ├── ai-practice-progress.md
       ├── ai-practice-todo.md
       ├── ai-practice-results/
       │   └── batch-01~29-results.md
       ├── ai-practice-consolidated/
       │   ├── AI-Practice-Master.md
       │   ├── deduplication-report.md
       │   └── categories/
       └── ai-practice-guides/
   ```

### 수정
5. **README.md** - '문서 인덱스' 섹션 추가 (기능별 분류)
6. **docs/user/EXAMPLES.md** - samples/ 핵심 예제 통합 + 실제 활용 사례 추가
7. **CHANGELOG.md** - 날짜 기준 형식으로 전환

### 삭제/이동
8. **plans/** 폴더 내용 → archive/ai-practice/
9. **samples/** 폴더 → 핵심 예제만 EXAMPLES.md에 통합 후 **폴더 삭제**
10. **ColBERT-Bug-Fix-Plan.md** → docs/dev/archive/
11. **test_driven_design.md** → docs/dev/archive/
12. **docs/README.md** → docs/에 유지 (전체 docs 네비게이션 역할)

---

## 상세 구현 계획

### Phase 1: 폴더 구조 생성 (5분)
```bash
mkdir -p docs/user docs/dev/archive archive/ai-practice
```

### Phase 2: 기존 문서 이동 (10분)
1. docs/ → docs/user/
   - QUICK_START.md, USER_GUIDE.md, EXAMPLES.md, TROUBLESHOOTING.md
2. docs/ → docs/dev/
   - embedding-upgrade-plan.md, multi-document-summarization-prd.md, phase9-implementation-plan.md, extract-dup-to-config.md, todo-embedding-upgrade.md
3. 루트 → docs/dev/archive/
   - ColBERT-Bug-Fix-Plan.md, test_driven_design.md
4. plans/ → archive/ai-practice/
   - 모든 ai-practice 관련 파일/폴더

### Phase 3: 신규 문서 작성 (30분)

#### 3.1 docs/AI-PRACTICE-SUMMARY.md
```markdown
# AI Practice 기법 수집 요약

## 개요
- 기간: 2025-01-03 ~ 2026-01-04
- 대상: 286개 문서 (~/DocumentsLocal/msbaek_vault/003-RESOURCES/AI)
- 결과: 2,319개 AI 기법 추출

## 카테고리별 주요 기법
[AI-Practice-Master.md 기반으로 요약]

## 상세 결과
→ archive/ai-practice/ 참조
```

#### 3.2 DEVELOPMENT.md
```markdown
# Vault Intelligence 개발 히스토리

## 개발 기간
2025-08-19 ~ 2025-12-13 (약 4개월)

## Phase별 타임라인
| Phase | 날짜 | 주요 기능 |
|-------|------|---------|
| 1 | 08-19 | Sentence Transformers 도입 |
| 2-3 | 08-20 | BGE-M3 하이브리드 검색 |
| ... |

## 실제 활용 사례
- ai-practice 기법 수집 (286개 문서 → 2,319개 기법)
- AI 한계 MOC 작성
- 브런치 글 작성 지원

## Claude Code 활용 패턴
[linear-imagining-bear.md 내용 기반]
```

### Phase 4: README.md 문서 인덱스 추가 (15분)

```markdown
## 문서 인덱스

### 빠른 시작
- [5분 빠른 시작](docs/user/QUICK_START.md)
- [설치 및 설정](#installation)

### 상세 가이드
- [전체 사용자 가이드](docs/user/USER_GUIDE.md) - 1,672라인 완전 매뉴얼
- [실전 예제](docs/user/EXAMPLES.md) - 워크플로우 및 활용 사례
- [문제 해결](docs/user/TROUBLESHOOTING.md)

### 개발자 참고
- [개발자 가이드](CLAUDE.md) - CLI 빠른 참조 (AI 최적화)
- [개발 히스토리](DEVELOPMENT.md) - Phase 1-9 개발 과정
- [변경 이력](CHANGELOG.md)
- [기여 가이드](CONTRIBUTING.md)
- [보안 정책](SECURITY.md)

### 산출물
- [AI Practice 요약](docs/AI-PRACTICE-SUMMARY.md) - 2,319개 기법 요약
- [상세 결과](archive/ai-practice/) - 배치별 결과 아카이브

### 설계 문서
- [설계 문서 모음](docs/dev/) - PRD, 구현 계획 등
```

### Phase 5: EXAMPLES.md 확장 (20분)
- samples/에서 핵심 예제 선별하여 인라인 포함
- 실제 활용 사례 추가:
  - AI 한계 MOC 작성 과정
  - 브런치 글 작성 지원 과정
  - ai-practice 기법 수집 과정

### Phase 6: CHANGELOG.md 형식 전환 (10분)
Keep a Changelog 형식으로 전환:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [2025-12-13]
### Added
- CLI quick reference and documentation audit report

## [2025-08-27]
### Fixed
- ColBERT metadata integrity and reranking support issues
...
```

### Phase 7: 정리 및 검증 (10분)
1. 불필요한 파일/폴더 정리
2. 모든 내부 링크 검증
3. git status 확인

---

## 검증 방법

1. **링크 검증**
   ```bash
   # 모든 마크다운 링크가 유효한지 확인
   fd -e md | xargs grep -l '\[.*\](.*\.md)' | head -10
   ```

2. **문서 구조 확인**
   ```bash
   tree docs/ archive/ -L 2
   ```

3. **README 인덱스 테스트**
   - 각 링크 클릭하여 올바른 문서로 이동하는지 확인

---

## 예상 소요 시간
- Phase 1-2 (구조/이동): 15분
- Phase 3-4 (신규 문서): 45분
- Phase 5-6 (수정): 30분
- Phase 7 (검증): 10분
- **총 예상: 약 100분**

---

## Uncertainty Map

### 높은 확신
- 폴더 구조 변경 계획
- 문서 이동 대상
- README 인덱스 구조
- samples/ 처리: 핵심만 통합 후 삭제
- docs/README.md: docs/에 유지

### 중간 확신
- AI-PRACTICE-SUMMARY.md 내용 범위 (AI-Practice-Master.md 기반이지만 어느 수준까지 요약할지)
- EXAMPLES.md에 포함할 samples/ 예제 선별 기준 (구현 시 판단)

### 낮은 확신
- CHANGELOG.md 날짜 기준 전환 시 기존 Phase 정보 유지 방법
