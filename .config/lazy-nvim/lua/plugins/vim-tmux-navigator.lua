-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/vim-tmux-navigator.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/vim-tmux-navigator.lua

-- https://github.com/christoomey/vim-tmux-navigator
--
-- This plugin allows me to switch between neovim and tmux panes using
-- ctrl+vim-motions, for it to work with tmux panes, you also need to install
-- the same plugin in tmux

return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false, -- 즉시 로드하여 안정적인 동작 보장
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate Down" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate Up" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate Right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
    },
  },
}
