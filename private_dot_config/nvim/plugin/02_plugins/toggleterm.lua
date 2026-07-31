require('core.utils').pack_add 'akinsho/toggleterm.nvim'
local current_count = 0
local function get_opts()
  current_count = current_count + 1
  return {
    size = 15,
    start_in_insert = false,
    direction = 'float',
    count = current_count,
  }
end
require('toggleterm').setup(get_opts())
vim.keymap.set('n', '<leader>ft', '<cmd>TermSelect<CR>', { desc = '[F]ind [T]erminal' })
vim.keymap.set({ 'n', 't' }, '<C-=>', function()
  local Terminal = require('toggleterm.terminal').Terminal
  local term = Terminal:new(get_opts())
  term:toggle()
end, { desc = 'Open new terminal' })
vim.keymap.set('n', '<C-j>', '<cmd>ToggleTerm<CR>', { desc = 'Toggle terminals' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><cmd>ToggleTermToggleAll<CR>', { desc = 'Toggle terminals' })
vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', 'kj', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
