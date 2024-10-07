-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- This add the bar that shows the file path on the top right
-- vim.opt.winbar = "%=%m %f"
--
-- Modified version of the bar, shows pathname on right, hostname left
-- vim.opt.winbar = "%=" .. vim.fn.systemlist("hostname")[1] .. "            %m %f"
--
-- This shows pathname on the left and hostname on the right
-- vim.opt.winbar = "%m %f%=" .. vim.fn.systemlist("hostname")[1]
--
-- Using different colors, defining the colors in this file
local colors = require("config.colors").load_colors()
vim.cmd(string.format([[highlight WinBar1 guifg=%s]], colors["linkarzu_color03"]))
vim.cmd(string.format([[highlight WinBar2 guifg=%s]], colors["linkarzu_color02"]))
-- Function to get the full path and replace the home directory with ~
local function get_winbar_path()
  local full_path = vim.fn.expand("%:p")
  return full_path:gsub(vim.fn.expand("$HOME"), "~")
end
-- Function to get the number of open buffers using the :ls command
local function get_buffer_count()
  local buffers = vim.fn.execute("ls")
  local count = 0
  -- Match only lines that represent buffers, typically starting with a number followed by a space
  for line in string.gmatch(buffers, "[^\r\n]+") do
    if string.match(line, "^%s*%d+") then
      count = count + 1
    end
  end
  return count
end
-- Function to update the winbar
local function update_winbar()
  local home_replaced = get_winbar_path()
  local buffer_count = get_buffer_count()
  vim.opt.winbar = "%#WinBar1#%m "
    .. "%#WinBar2#("
    .. buffer_count
    .. ") "
    .. "%#WinBar1#"
    .. home_replaced
    .. "%*%=%#WinBar2#"
    .. vim.fn.systemlist("hostname")[1]
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  callback = update_winbar,
})

-- -- This is my old way of updating the winbar but it stopped working, it
-- -- wasn't showing the entire path, it was being truncated in some dirs
-- vim.opt.winbar = "%#WinBar1#%m %f%*%=%#WinBar2#" .. vim.fn.systemlist("hostname")[1]

-- If set to 0 it shows all the symbols in a file, like bulletpoints and
-- codeblock languages, obsidian.nvim works better with 1 or 2
-- Set it to 2 if using kitty or codeblocks will look weird
vim.opt.conceallevel = 0

-- Enable autochdir to automatically change the working directory to the current file's directory
-- If you go inside a subdir, neotree will open that dir as the root
-- vim.opt.autochdir = true

-- Keeps my cursor in the middle whenever possible
-- This didn't work as expected, but the `stay-centered.lua` plugin did the trick
-- vim.opt.scrolloff = 999

-- When text reaches this limit, it automatically wraps to the next line.
-- This WILL NOT auto wrap existing lines, or if you paste a long line into a
-- file it will not wrap it as well
-- https://www.reddit.com/r/neovim/comments/1av26kw/i_tried_to_figure_it_out_but_i_give_up_how_do_i/
vim.opt.textwidth = 80

-- Above option applies the setting to ALL file types, if you want to apply it
-- to specific files only
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "markdown",
--   -- pattern = {"python", "javascript", "html"},
--   callback = function()
--     vim.opt_local.textwidth = 80
--   end,
-- })

-- Shows colorcolumn that helps me with markdown guidelines. This applies to ALL
-- file types
vim.opt.colorcolumn = "80"

-- -- To apply it to markdown files only
-- vim.api.nvim_create_autocmd("BufWinEnter", {
--   pattern = { "*.md" },
--   callback = function()
--     vim.opt.colorcolumn = "80"
--     vim.opt.textwidth = 80
--   end,
-- })

-- I added `localoptions` to save the language spell settings, otherwise, the
-- language of my markdown documents was not remembered if I set it to spanish
-- or to both en,es
-- See the help for `sessionoptions`
-- `localoptions`: options and mappings local to a window or buffer
-- (not global values for local options)
--
-- The plugin that saves the session information is
-- https://github.com/folke/persistence.nvim and comes enabled in the
-- lazyvim.org distro lamw25wmal
--
-- These sessionoptions come from the lazyvim distro, I just added localoptions
-- https://www.lazyvim.org/configuration/general
vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "help",
  "globals",
  "skiprtp",
  "folds",
  "localoptions",
}

-- Most of my files have 2 languages, spanish and english, so even if I set the
-- language to spanish, I always add some words in English to my documents, so
-- it's annoying to be adding those to the spanish dictionary
-- vim.opt.spelllang = { "en,es" }

-- I mainly type in english, if I set it to both above, files in English get a
-- bit confused and recognize words in spanish, just for spanish files I need to
-- set it to both
vim.opt.spelllang = { "en" }

-- My cursor was working fine, not  sure why it stopped working in wezterm, so this fixed it
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"
