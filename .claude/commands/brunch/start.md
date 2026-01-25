# 브런치 글쓰기 시작 (Phase 1: Seed)

초안 파일을 분석하고 vault에서 관련 자료를 검색합니다.

## 사용법
```
/brunch:start [파일경로]
```

예시: `/brunch:start /Users/msbaek/temp/junior.md`

---

## 수행할 작업

### 1. 초안 파일 분석
$ARGUMENTS 파일을 읽고 다음을 추출하세요:
- 핵심 주제/키워드 3-5개
- 사용자가 전달하고자 하는 핵심 메시지
- 언급된 개인 경험이나 에피소드
- 원하는 결과물 형태 (MOC, 구조, 초안 등)

### 2. vault-intelligence로 관련 자료 검색
```bash
cd ~/git/vault-intelligence

# 각 키워드별 검색 (병렬 실행 권장)
python -m src search --query "키워드1" --search-method hybrid --top-k 15 --rerank --expand
python -m src search --query "키워드2" --search-method hybrid --top-k 15 --rerank

# MOC 생성 (구조화 참고용)
python -m src generate-moc --topic "주제" --top-k 30
```

### 3. 결과 정리

다음 형식으로 사용자에게 제공:

```markdown
## 초안 분석 결과

### 추출된 핵심 키워드
1. 키워드1
2. 키워드2
3. 키워드3

### 핵심 메시지 (사용자 의도)
- [사용자가 전달하려는 핵심 메시지]

### vault에서 찾은 관련 문서 (상위 10개)
| 문서명 | 유사도 | 핵심 내용 |
|--------|--------|----------|
| 문서1.md | 0.85 | 관련 요약 |
| 문서2.md | 0.78 | 관련 요약 |
| ... | ... | ... |

### 다음 단계
구조(skeleton)를 제안해 드릴까요?
- `/brunch:skeleton` 명령으로 구조 제안 받기
- 또는 더 찾아볼 자료가 있으면 말씀해주세요
```

---

## 핵심 원칙
- Claude는 글을 대신 쓰지 않음
- 자료 수집과 정리만 수행
- 사용자가 주도적으로 결정
