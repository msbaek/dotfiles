return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          -- second key is the lefthand side of the map
          -- mappings seen under group name "Buffer"
          ["<Leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
          ["<Leader>bD"] = {
            function()
              require("astroui.status").heirline.buffer_picker(
                function(bufnr) require("astrocore.buffer").close(bufnr) end
              )
            end,
            desc = "Pick to close",
          },
          -- tables with the `name` key will be registered with which-key if it's installed
          -- this is useful for naming menus
          ["<Leader>b"] = { name = "Buffers" },
          -- quick save
          -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
          -- ["<C-s>"] = { "<cmd>w!<cr>", desc = "force save" },
          ["<Tab>"] = { "<cmd>bn<cr>", desc = "Next tab" },
          ["<S-Tab>"] = { "<cmd>bp<cr>", desc = "Previous Tab" },
          ["<leader>a"] = { "ggVG", desc = "select all" },
          ["<leader>-"] = { "<cmd>split<cr>", desc = "vsplit" },
          ["<leader>|"] = { "<cmd>vsplit<cr>", desc = "split" },
          -- ["sh"] = { "<cmd>TmuxNavigateLeft<cr>", desc = "move to left pane" },
          -- ["sl"] = { "<cmd>TmuxNavigateRight<cr>", desc = "move to Right pane" },
          -- ["sj"] = { "<cmd>TmuxNavigateUp<cr>", desc = "move to up pane" },
          -- ["<Leader>sk"] = { "<cmd>TmuxNavigateDown<cr>", desc = "move donw" },

          -- increment/decrement numbers
          -- ["<leader>+"] = { "<C-a>", desc = "Increment number" }, -- increment
          -- ["<leader>-"] = { "<C-x>", desc = "Decrement number" }, -- decrement
          -- ["<C-k>"] = { ":wincmd k<CR>", desc = "Move to window above" },
          -- ["<C-j>"] = { ":wincmd j<CR>", desc = "Move to window below" },
          -- ["<C-h>"] = { ":wincmd h<CR>", desc = "Move to window right" },
          -- ["<C-l>"] = { ":wincmd l<CR>", desc = "Move to window left" },
          -- map("n", "<leader>fs", "<cmd>set ft=sql<cr>")
          -- map("n", "<leader>fd", "<cmd>set ft=markdown<cr>")
          -- map("n", "<leader>fj", "<cmd>set ft=java<cr⌘ ⌥ ⇧>")
        },
        t = {
          -- setting a mapping to false will disable it
          -- ["<esc>"] = false,
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      mappings = {
        n = {
          -- this mapping will only be set in buffers with an LSP attached
          K = {
            function() vim.lsp.buf.hover() end,
            desc = "Hover symbol details",
          },
          -- condition for only server with declaration capabilities
          gD = {
            function() vim.lsp.buf.declaration() end,
            desc = "Declaration of current symbol",
            cond = "textDocument/declaration",
          },
        },
      },
    },
  },
}
