return {
  'mbbill/undotree',
  config = function()
    vim.keymap.set('n', '<leader>tu', ':UndotreeToggle<CR>:UndotreeFocus<CR>', { desc = '[T]oggle [U]ndotree' })
  end,
}
