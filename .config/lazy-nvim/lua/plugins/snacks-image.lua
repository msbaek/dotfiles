-- Enable snacks.image for inline image preview in markdown
-- Supports Ghostty/Kitty/WezTerm via Kitty Graphics Protocol
return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
        },
      },
    },
  },
}
