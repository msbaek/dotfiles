-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/gitsigns.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/gitsigns.lua

-- Plugin that shows git changes in the left sign column
-- I also use this plugin to run ghd and see the diff in the current buffer, I
-- like having wrap on the vim splits, so that's why I added folke's config here
-- https://www.lazyvim.org/plugins/editor#gitsignsnvim

return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      -- stylua: ignore start
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")
      map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
      map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
      map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
      map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
      -- map("n", "<leader>ghd", gs.diffthis, "Diff This")
      -- Enable wrap in both diff windows
      map("n", "<leader>ghd", function()
        gs.diffthis()
        vim.cmd("windo set wrap")
      end, "Diff This")
      map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      -- Open the file as it was at the commit that last changed this line, in a new tab
      -- (ported from craftzdog/dotfiles <leader>go; that key is used by mini.diff here)
      map("n", "<leader>ghO", function()
        local async = require("gitsigns.async")
        local cache = require("gitsigns.cache").cache
        async.run(function()
          local bufnr = vim.api.nvim_get_current_buf()
          local lnum = vim.api.nvim_win_get_cursor(0)[1]
          local bcache = cache[bufnr]
          if not bcache then
            return
          end
          bcache:get_blame(lnum)
          local entry = bcache.blame and bcache.blame.entries and bcache.blame.entries[lnum]
          if not entry then
            return
          end
          local sha = entry.commit.sha
          if tonumber("0x" .. sha:sub(1, 8)) == 0 then
            vim.notify("Line not committed yet", vim.log.levels.WARN)
            return
          end
          vim.cmd.tabnew()
          require("gitsigns.actions.diffthis").show(bufnr, sha, entry.filename)
          async.schedule()
          pcall(vim.api.nvim_win_set_cursor, 0, { entry.orig_lnum or lnum, 0 })
        end)
      end, "Open File at Blamed Commit")
    end,
  },
}
