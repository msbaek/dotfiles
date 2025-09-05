return {
  "szw/vim-maximizer",
  config = function()
    vim.g.maximizer_set_default_mapping = 0
    vim.api.nvim_set_keymap("n", "<leader>z", ":MaximizerToggle!<CR>", { noremap = true, silent = true })
  end,
}
