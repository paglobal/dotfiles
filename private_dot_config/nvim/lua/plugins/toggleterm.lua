local current_count = 0

local function get_opts()
  current_count = current_count + 1

  local opts = {
    size = 15,
    start_in_insert = false,
    direction = 'float',
    count = current_count,
  }

  return opts
end

return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup(get_opts())
    vim.keymap.set('n', '<leader>ft', ':TermSelect<CR>', { desc = '[F]ind [T]erminal' })
    vim.keymap.set({ 'n', 't' }, '<C-=>', function()
      local Terminal = require('toggleterm.terminal').Terminal
      local term = Terminal:new(get_opts())
      term:toggle()
    end, { desc = 'Open new terminal' })
    vim.keymap.set('n', '<C-j>', ':ToggleTerm<CR>', { desc = 'Toggle terminals' })
    vim.keymap.set('t', '<C-j>', '<C-\\><C-n>:ToggleTermToggleAll<CR>', { desc = 'Toggle terminals' })
    vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
    vim.keymap.set('t', 'kj', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
    vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
  end,
}
