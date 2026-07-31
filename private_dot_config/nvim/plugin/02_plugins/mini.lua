require('core.utils').pack_add 'nvim-mini/mini.nvim'
require('mini.icons').setup()
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()
require('mini.comment').setup {
  mappings = {
    comment = '<leader>cc',
    comment_line = '<leader>cc',
    comment_visual = '<leader>cc',
    textobject = '<leader>cc',
  },
}
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end
