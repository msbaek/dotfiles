-- codediff.nvim: side-by-side diff + file/repo history for reviewing large agent changes.
-- Ported from craftzdog/dotfiles (devaslife "Effective Neovim setup for agentic coding").
return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>dv", "<cmd>CodeDiff<cr>", desc = "Toggle CodeDiff" },
      { "<leader>dh", "<cmd>CodeDiff history %<cr>", desc = "File history (current file)" },
      { "<leader>dH", "<cmd>CodeDiff history<cr>", desc = "File history (repo)" },
    },
    opts = {
      explorer = {
        width = 50,
        auto_open_on_cursor = true,
        view_mode = "tree",
        line_stats = { enabled = true },
      },
      diff = {
        compact = true,
        compact_context_lines = 8,
        compact_sync_folds = true,
      },
    },
    config = function(_, opts)
      -- Workaround for neovim/neovim#40290 (copied from the author's workarounds.lua):
      -- treesitter fold refresh on 'foldminlines' change crashes with "Invalid buffer id"
      -- in codediff's compact mode. Remove once fixed in a Neovim release.
      require("vim.treesitter._fold")
      for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "OptionSet" })) do
        if au.desc == "Refresh treesitter folds" then
          vim.api.nvim_del_autocmd(au.id)
        end
      end
      require("codediff").setup(opts)
    end,
  },
}
