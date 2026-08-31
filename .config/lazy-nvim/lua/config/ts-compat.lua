-- Neovim 0.12 compatibility shim for nvim-treesitter (frozen `master` branch).
--
-- In 0.12 the `match` table handed to treesitter predicates/directives maps a
-- capture id to a LIST of TSNodes (`TSNode[]`), not to a single TSNode.
-- nvim-treesitter's master branch is frozen at a pre-0.12 commit and still
-- treats `match[id]` as one node, so its predicates/directives blow up with
--   treesitter.lua:197: attempt to call method 'range' (a nil value)
-- as soon as an injection query runs (markdown/html code blocks, for example).
--
-- Wrap the affected registrations so they receive the last node of each list --
-- exactly what nvim-treesitter `main` does. Remove this file once the plugin
-- stack moves to LazyVim 15.x / nvim-treesitter `main`.

local M = {}

local PATCHED = {
  ["nth?"] = true,
  ["is?"] = true,
  ["kind-eq?"] = true,
  ["set-lang-from-mimetype!"] = true,
  ["set-lang-from-info-string!"] = true,
  ["downcase!"] = true,
}

---@param match table<integer, any>
---@return table<integer, any>
local function unwrap_nodes(match)
  local single = {}
  for id, nodes in pairs(match) do
    -- TSNode is userdata; only a plain table is the new list form.
    single[id] = type(nodes) == "table" and nodes[#nodes] or nodes
  end
  return single
end

function M.setup()
  if vim.fn.has("nvim-0.12") ~= 1 then
    return
  end

  local query = vim.treesitter.query

  for _, register in ipairs({ "add_predicate", "add_directive" }) do
    local original = query[register]
    query[register] = function(name, handler, opts)
      if PATCHED[name] and type(handler) == "function" then
        local inner = handler
        handler = function(match, ...)
          return inner(unwrap_nodes(match), ...)
        end
      end
      return original(name, handler, opts)
    end
  end
end

return M
