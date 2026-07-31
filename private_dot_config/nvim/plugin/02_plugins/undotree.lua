require('core.utils').pack_add 'mbbill/undotree'
vim.keymap.set('n', '<leader>tu', '<cmd>UndotreeToggle<CR><cmd>UndotreeFocus<CR>', { desc = '[T]oggle [U]ndotree' })
