-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/markdown-preview.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/markdown-preview.lua
--
-- Link to github repo
-- https://github.com/iamcco/markdown-preview.nvim
-- Preview Markdown in your modern browser with synchronised scrolling and flexible configuration
-- return {
--   "iamcco/markdown-preview.nvim",
--   cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
--   ft = { "markdown" },
--   build = "cd app && yarn install",
--   init = function()
--     vim.g.mkdp_filetypes = { "markdown" }
--   end,
--   -- build = function()
--   --   vim.fn["mkdp#util#install"]()
--   -- end,
--   keys = {
--     {
--       "<leader>mp",
--       ft = "markdown",
--       "<cmd>MarkdownPreviewToggle<cr>",
--       desc = "Markdown Preview",
--     },
--   },
-- }
-- return {
--   "davidgranstrom/nvim-markdown-preview",
-- }

return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_theme = "" -- 다크 테마 적용
  end,
}
