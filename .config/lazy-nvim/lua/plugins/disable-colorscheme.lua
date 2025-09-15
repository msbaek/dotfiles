-- This file completely disables LazyVim's default colorscheme configuration
-- to prevent bufferline integration errors

return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Disable the colorscheme entirely to prevent bufferline integration issues
      colorscheme = nil,
    },
  },
}
