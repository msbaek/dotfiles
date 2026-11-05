-- lazygit `e` opens the file in the window lazygit was launched from.
-- The <leader>gg / <leader>gG overrides live in lua/config/keymaps.lua, because
-- LazyVim registers its own defaults on VeryLazy, after plugin-spec keys.
local lg = require("agentic.lazygit")

return {
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = {
        config = {
          os = {
            edit = lg.edit_command(),
            editAtLine = lg.edit_command({ at_line = true }),
          },
        },
      },
    },
  },
}
