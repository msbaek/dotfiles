# Tmux-Neovim Ctrl+hjkl 이동 문제 해결 계획

## 문제 요약
- **증상**: nvim 윈도우 → tmux pane 이동 불가
- **발생 시점**: 최근 업데이트 후
- **반대 방향**: tmux pane → nvim은 정상 작동

## 원인 분석

### 발견된 문제점
1. **Neovim 키 바인딩 형식**: `<C-U>` 누락
   - 현재: `<cmd>TmuxNavigateLeft<cr>`
   - 권장: `<cmd><C-U>TmuxNavigateLeft<cr>`
   - `<C-U>`는 visual mode count를 제거하여 안정적 동작 보장

2. **focus-events 미설정**: tmux에서 focus 이벤트가 neovim에 전달되지 않을 수 있음

---

## 실행 계획

### Step 1: 진단 (선택사항)
nvim에서 실행하여 현재 상태 확인:
```vim
:verbose nmap <C-h>
```
- 예상: `TmuxNavigateLeft` 매핑 표시

### Step 2: Neovim 플러그인 설정 수정
**파일**: `/Users/msbaek/dotfiles/.config/lazy-nvim/lua/plugins/vim-tmux-navigator.lua`

```lua
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,  -- 즉시 로드로 변경
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate Down" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate Up" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate Right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
    },
  },
}
```

**변경 사항**:
- `cmd = {...}` 블록 제거
- `lazy = false` 추가 (즉시 로드)
- 모든 키 바인딩에 `<C-U>` 추가

### Step 3: Tmux 설정에 focus-events 추가 (선택사항)
**파일**: `/Users/msbaek/dotfiles/.tmux.conf`

TPM 실행 전(line 192 이전)에 추가:
```bash
set -g focus-events on
```

### Step 4: 설정 적용
```bash
# Neovim 재시작
# tmux 설정 리로드
tmux source-file ~/.tmux.conf
```

### Step 5: 테스트
1. tmux에서 2개 이상의 pane 생성
2. 한 pane에서 nvim 실행
3. Ctrl+hjkl로 nvim → tmux pane 이동 확인

---

## 수정 대상 파일
| 파일 | 수정 내용 |
|------|----------|
| `.config/lazy-nvim/lua/plugins/vim-tmux-navigator.lua` | `<C-U>` 추가 + lazy=false |
| `.tmux.conf` (선택) | focus-events on 추가 |

---

## Uncertainty Map
- **단순화**: Step 2만으로 해결될 가능성 높음, Step 3은 보조적
- **불확실**: tmux 버전에 따른 is_vim 패턴 호환성 (현재 3.6a는 정상 지원)
