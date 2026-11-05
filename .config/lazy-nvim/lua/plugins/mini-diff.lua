-- mini.diff overlay for reviewing agent-written changes inside the buffer.
-- Ported from craftzdog/dotfiles (devaslife "Effective Neovim setup for agentic coding").
-- Uses the author's fork, which groups changes into whole hunks like `git diff`.
-- gitsigns stays enabled for signs/blame/staging; mini.diff is used only for the overlay.
-- (The LazyVim `editor.mini-diff` extra is NOT used because it disables gitsigns.)
return {
  {
    "craftzdog/mini.diff",
    name = "mini.diff",
    branch = "feat/grouping",
    event = "VeryLazy",
    keys = {
      {
        "<leader>go",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "Toggle mini.diff overlay",
      },
    },
    opts = {
      view = {
        -- show whole reference part above whole buffer part, as in `git diff`
        overlay_style = "hunk",
      },
      mappings = {
        -- gitsigns already provides ]h / [h hunk navigation
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
    },
  },
}
