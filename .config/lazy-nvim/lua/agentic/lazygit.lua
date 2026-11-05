-- Open files selected in lazygit (`e`) in the window lazygit was launched from,
-- instead of the nvim-remote preset's new tab.
-- Ported from craftzdog/dotfiles utils/lazygit.lua; fish syntax rewritten to POSIX sh
-- because lazygit runs os.edit through $SHELL (zsh here).
local M = {}

local origin_win = nil

--- Open lazygit, remembering the focused window as the target for `e`.
---@param opts? table passed to Snacks.lazygit()
function M.open(opts)
  origin_win = vim.api.nvim_get_current_win()
  Snacks.lazygit(opts)
end

--- Focus the launch window. No-op when it was closed while lazygit was open.
function M.focus_origin()
  if origin_win and vim.api.nvim_win_is_valid(origin_win) then
    pcall(vim.api.nvim_set_current_win, origin_win)
  end
end

local nvim_server = 'nvim --server "$NVIM"'
local focus_launch_pane = nvim_server
  .. [[ --remote-send '<Cmd>lua require("agentic.lazygit").focus_origin()<CR>']]

--- Build a lazygit os.edit / os.editAtLine command (POSIX sh).
---@param opts? { at_line?: boolean }
---@return string
function M.edit_command(opts)
  local at_line = opts and opts.at_line

  -- No $NVIM: lazygit was launched outside neovim, so edit directly.
  local outside_neovim = at_line and "nvim +{{line}} -- {{filename}}" or "nvim -- {{filename}}"

  -- Inside neovim: quit lazygit, return to the launch window, open the file there.
  local inside_neovim = {
    nvim_server .. " --remote-send q",
    focus_launch_pane,
    nvim_server .. " --remote {{filename}}",
  }
  if at_line then
    inside_neovim[#inside_neovim + 1] = nvim_server .. ' --remote-send ":{{line}}<CR>"'
  end

  return ('if [ -z "$NVIM" ]; then %s; else %s; fi'):format(outside_neovim, table.concat(inside_neovim, "; "))
end

return M
