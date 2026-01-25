# 파일 병합 계획

## 개요
**소스 파일**: `000-SLIPBOX/AI-시대-주니어-개발자-생존-가이드-MOC.md`
**대상 파일**: `003-RESOURCES/ai/LIMITATIONS/AI-문제점-종합-분석.md`

## 분석 결과

### 대상 파일의 현재 상태
- 이미 매우 포괄적인 문서 (약 1400줄)
- frontmatter에 "AI 시대 주니어 개발자 생존 가이드" 관련 alias와 태그 포함
- 섹션 15에서 "신입 개발자 성장 로드맵" 포함
- 소스 파일의 대부분 내용이 이미 통합되어 있음

### 소스 파일 고유 콘텐츠 (병합 필요)
1. **핵심 인용구 모음** (섹션 328-339줄) - 대상 파일에 없음
2. **관련 문서 전체 목록** (섹션 342-372줄) - 일부만 대상 파일에 있음
3. **Uncertainty Map** (섹션 376-387줄) - 대상 파일에 없음
4. **개요의 핵심 메시지** 요약 (28-31줄)

### 중복 콘텐츠 (이미 대상 파일에 존재)
- 위기 인식 통계 (73.4% 감소 등)
- AI 한계 (환각, 본질적 복잡성)
- 새롭게 요구되는 핵심 역량
- 성장 전략 (평판, 영향력, Self-PR)
- 5단계 성장 로드맵 (Dave Farley)
- 실천 체크리스트

## 병합 작업 계획

### Step 1: Frontmatter 업데이트
- 소스 파일의 alias "AI 시대 주니어 개발자 성장 전략", "Junior Developer Survival Guide in AI Era" 추가 (이미 유사한 것 있으면 확인)
- 소스 파일의 태그 `career/mentoring` 추가 (없는 경우)

### Step 2: 새 섹션 추가 (문서 끝에)
대상 파일 끝에 다음 섹션 추가:

#### 20. 핵심 인용구 모음
소스 파일의 328-339줄 내용

#### 21. 관련 문서 전체 목록
소스 파일의 344-372줄 내용 (대상 파일에 없는 링크만 추가)

#### Uncertainty Map 업데이트
기존 Uncertainty Map에 소스 파일의 내용 병합

### Step 3: 소스 파일 삭제
`000-SLIPBOX/AI-시대-주니어-개발자-생존-가이드-MOC.md` 삭제

### Step 4: Git 작업
- 변경사항 확인 및 커밋

## 수정 대상 파일
1. `/Users/msbaek/DocumentsLocal/programmer-in-ai-era/003-RESOURCES/ai/LIMITATIONS/AI-문제점-종합-분석.md` - 수정
2. `/Users/msbaek/DocumentsLocal/programmer-in-ai-era/000-SLIPBOX/AI-시대-주니어-개발자-생존-가이드-MOC.md` - 삭제
