local M = {}
---@param repo string
---@return string
local function gh(repo)
  return 'https://github.com/' .. repo
end
---@param repo string
---@param opts? table
function M.pack_add(repo, opts)
  local spec = vim.tbl_extend('force', { src = gh(repo) }, opts or {})
  vim.pack.add { spec }
end
M.map = function(keys, func, desc, mode, buffer)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = desc, buffer = buffer })
end
return M
