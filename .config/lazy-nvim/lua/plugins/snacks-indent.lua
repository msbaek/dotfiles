-- Neovim 0.12 workaround for snacks.nvim (frozen at 2025-02-25).
--
-- 0.12 parses treesitter asynchronously, so snacks' scope callbacks fire on a
-- later event-loop tick. The indent *animation* keeps the window id it started
-- with and calls `nvim_win_get_cursor(scope.win)` without checking validity:
--   snacks/indent.lua:392: Invalid window id: 1001
-- Upstream fixed this by guarding with `nvim_win_is_valid`; this pin predates
-- that commit, so turn the animation off instead. Indent guides and scope
-- highlighting stay on -- only the animated reveal is dropped.
--
-- Remove this file once snacks.nvim is updated past the guard.

return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      animate = { enabled = false },
    },
  },
}
