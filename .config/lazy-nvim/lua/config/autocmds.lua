-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- LazyVim은 기본적으로 마크다운 파일에서 spell check를 활성화함
-- 이를 덮어쓰기 위해 나중에 실행되도록 설정
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- 약간의 지연 후 실행하여 LazyVim의 설정을 덮어씀
    vim.defer_fn(function()
      vim.opt.spell = false
      -- 현재 버퍼의 spell도 비활성화
      vim.opt_local.spell = false
    end, 100)
  end,
})

-- 파일 타입별로도 강제로 비활성화
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" }, -- LazyVim이 spell을 활성화하는 파일 타입들
  callback = function()
    vim.opt_local.spell = false
  end,
})
