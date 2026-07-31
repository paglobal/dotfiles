require('core.utils').pack_add 'stevearc/oil.nvim'
require('mini.icons').setup()
require('oil').setup()
vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })
