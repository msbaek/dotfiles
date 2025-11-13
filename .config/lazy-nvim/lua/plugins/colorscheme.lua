-- I manually created this file
return {
  -- GitHub Theme
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        options = {
          transparent = false,
          terminal_colors = true,
          dim_inactive = false,
          module_default = true,
          styles = {
            comments = "italic",
            keywords = "bold",
            types = "italic,bold",
          },
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      -- GitHub Light theme
      colorscheme = "github_light",
      -- Previous: catppuccin-latte
      -- colorscheme = "catppuccin-latte",
      -- colorscheme = "catppuccin-macchiato",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "catppuccin",
      -- colorscheme = "eldritch",
      -- colorscheme = "catppuccin-frappe",
      -- colorscheme = "Duskfox",
      -- colorscheme = "Nightfox",
      -- colorscheme = "Carbonfox",
      -- colorscheme = "gruvbox",
    },
  },
}
