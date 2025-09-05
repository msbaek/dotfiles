-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/nvim-lspconfig.lua
-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/nvim-lspconfig.lua
--
-- https://github.com/neovim/nvim-lspconfig
-- :help lspconfig-all from Nvim.
-- Commands
-- :LspInfo (deprecated alias to :che lspconfig) shows the status of active and configured language servers.
-- :LspStart <config_name> Start the requested server name. Will only successfully start if the command detects a root directory matching the current config. Pass autostart = false to your .setup{} call for a language server if you would like to launch clients solely with this command. Defaults to all servers matching current buffer filetype.
-- :LspStop <client_id> Defaults to stopping all buffer clients.
-- :LspRestart <client_id> Defaults to restarting all buffer clients.
local lsp = "intelephense"

return {
  "neovim/nvim-lspconfig",
  opts = {

    -- This disables inlay hints
    -- When programming in Go, these made my experience feel like shit, because were
    -- very intrusive and I never got used to them.
    --
    -- Folke has a keymap to toggle inaly hints with <leader>uh
    inlay_hints = { enabled = false },

    servers = {
      -- phpactor = {
      --   enabled = lsp == "phpactor",
      -- },
      intelephense = {
        enabled = lsp == "intelephense",
      },
      [lsp] = {
        enabled = true,
      },
    },
  },
}
