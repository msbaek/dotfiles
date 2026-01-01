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
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
      { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
    },
  },
}
